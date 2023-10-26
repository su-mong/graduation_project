// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UserIdentificationType, APICallStatus} from "graduation_project_library/utils/Enums.sol";
import {UnexpectedRequestID, WrongMethodForUserIdentificationType, UserIdentifierWalletAddressNotMatching, ApiCallNotFinishedYet} from "graduation_project_library/utils/Errors.sol";
import {Utils} from "graduation_project_library/utils/Utils.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

abstract contract VoteIdBaseContract is FunctionsClient, ConfirmedOwner {
  using FunctionsRequest for FunctionsRequest.Request;

  UserIdentificationType private immutable _identificationType;
  uint private immutable _uuidSeed;
  uint64 private immutable _subscriptionId;
  uint32 private immutable _gasLimit;
  bytes32 private immutable _jobId;
  string private _verifyUserIdentifierCallJavascriptSource;

  /// @notice Struct for saving voteId. It is used for mapWalletAddressVoteId in VoteBackendBase.
  struct VoteIdData {
    string voteId;
    bool isExist;
  }

  enum ResultCheckUserIsVoted {
    error,
    notExist,
    exist
  }

  // 생성자
  constructor(
    address router,
    UserIdentificationType identificationType,
    uint uuidSeed,
    uint64 subscriptionId,
    uint32 gasLimit,
    bytes32 jobId,
    string memory verifyUserIdentifierCallJavascriptSource
  ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
    _identificationType = identificationType;
    _uuidSeed = uuidSeed;
    _subscriptionId = subscriptionId;
    _gasLimit = gasLimit;
    _jobId = jobId;
    _verifyUserIdentifierCallJavascriptSource = verifyUserIdentifierCallJavascriptSource;
  }

  event ResponseVerifyUser(bytes32 indexed requestId, bytes response, bytes err);

  bytes32 public _lastRequestIdVerifyUser;
  bytes public _lastResponseVerifyUser;
  bytes public _lastErrorVerifyUser;

  /// 유저 식별자 -> 지갑 주소 mapping
  mapping(string => address) private mapUserIdWalletAddress;
  /// 지갑 주소 -> VoteId mapping
  mapping(address => VoteIdData) private mapWalletAddressVoteId;
  /// verifyUserIdentifier에 대한 requestId -> API 처리 여부 mapping
  mapping(bytes32 => APICallStatus) private _apiStatusVerifyUser;
  /// 현재까지 발급된 voteId 저장
  mapping(string => bool) private _voteIdIssued;

  /// @notice call the external API that phonenumber is valid
  /// @param args: arguments for API Call
  /// @return requestId : chainlink requestId. It can use listening ResponseVerifyUser event.
  function callVerifyUserIdentifierApi(string[] memory args) public returns(bytes32 requestId) {
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(_verifyUserIdentifierCallJavascriptSource);
      
    if (args.length > 0) req.setArgs(args);
      
    // function _sendRequest(bytes data, uint64 subscriptionId, uint32 callbackGasLimit, bytes32 donId) internal returns (bytes32)
    _lastRequestIdVerifyUser = _sendRequest(
      req.encodeCBOR(),
      _subscriptionId,
      _gasLimit,
      _jobId
    );

    _apiStatusVerifyUser[_lastRequestIdVerifyUser] = APICallStatus.loading;

    return _lastRequestIdVerifyUser;
  }

  function showVoteId(address walletId) internal view returns(string memory) {
    return mapWalletAddressVoteId[walletId].voteId;
  }

  function issueVoteIdByPhone(string calldata identifier, address walletId) internal returns(string memory) {
    string memory voteId = makeUniqueVoteId(walletId, identifier);
    return voteId;

    /*if(_identificationType != UserIdentificationType.phone) {
      revert WrongMethodForUserIdentificationType();
    } else {
      // verifyUserIdentifier를 끝마쳤는지 확인
      bool isFinished = isVerifyUserIdentifierApiCallFinished(_lastRequestIdVerifyUser);

      if(isFinished) {
        // 투표 여부를 확인
        ResultCheckUserIsVoted isUserVoted = checkUserIsVoted(walletId, identifier);

        if(isUserVoted == ResultCheckUserIsVoted.error) {
          revert UserIdentifierWalletAddressNotMatching(identifier);
        } else if(isUserVoted == ResultCheckUserIsVoted.exist) {
          _apiStatusVerifyUser[_lastRequestIdVerifyUser] = APICallStatus.notYet;
          // 투표한 계정이면 -> 해당 계정의 voteId를 찾아서 리턴
          return mapWalletAddressVoteId[walletId].voteId;
        } else {
          _apiStatusVerifyUser[_lastRequestIdVerifyUser] = APICallStatus.notYet;
          // 투표한 적이 없다면 -> 새로운 voteId를 만든 뒤, 등록하고 리턴.
          string memory voteId = makeUniqueVoteId(walletId, identifier);
          return voteId;
        }
      } else {
        revert ApiCallNotFinishedYet(_lastRequestIdVerifyUser);
      }
    }*/
  }

  function issueVoteIdByWallet(address walletId) internal returns(string memory) {
    if(_identificationType != UserIdentificationType.wallet) {
      revert WrongMethodForUserIdentificationType();
    } else {
      // 투표 여부를 확인
      ResultCheckUserIsVoted isUserVoted = checkUserIsVoted(walletId);

      if(isUserVoted == ResultCheckUserIsVoted.exist) {
        _apiStatusVerifyUser[_lastRequestIdVerifyUser] = APICallStatus.notYet;
        // 투표한 계정이면 -> 해당 계정의 voteId를 찾아서 리턴
        return mapWalletAddressVoteId[walletId].voteId;
      } else {
        _apiStatusVerifyUser[_lastRequestIdVerifyUser] = APICallStatus.notYet;
        // 투표한 적이 없다면 -> 새로운 voteId를 만든 뒤, 등록하고 리턴.
        string memory voteId = makeUniqueVoteId2(walletId);
        return voteId;
      }
    }
  }

  /// @dev used for vote process
  function checkVoteIdIsValid(string memory voteId) internal view returns(bool) {
    return _voteIdIssued[voteId];
  }

  /// @notice Checks whether processing for API calls corresponding to requestId is complete.
  function isVerifyUserIdentifierApiCallFinished(bytes32 requestId) private onlyOwner view returns(bool) {
    bool isFinished = _apiStatusVerifyUser[requestId] == APICallStatus.finished;
    return isFinished;
  }
  

  /// 기존에 투표한 이력이 있는지 검사하는 내부 함수.
  /// user 식별자 -> bool
  function checkUserIsVoted(address walletId, string calldata identifier) private view returns(ResultCheckUserIsVoted) {
    if(mapUserIdWalletAddress[identifier] == address(0)) {
      return ResultCheckUserIsVoted.notExist;
    } else if (mapUserIdWalletAddress[identifier] != walletId) {
      return ResultCheckUserIsVoted.error;
    } else {
      if(mapWalletAddressVoteId[walletId].isExist == true) {
        return ResultCheckUserIsVoted.exist;
      } else {
        return ResultCheckUserIsVoted.notExist;
      }
    }
  }

  function checkUserIsVoted(address walletId) private view returns(ResultCheckUserIsVoted) {
    if(mapWalletAddressVoteId[walletId].isExist == true) {
      return ResultCheckUserIsVoted.exist;
    } else {
      return ResultCheckUserIsVoted.notExist;
    }
  }

  /// (투표 이력이 없다면 실행) voteId를 생성한 후 유저에게 제공. 정확히는 아래의 역할을 수행한다.
  /// 1. 중복되지 않는 voteId를 생성한다.
  /// 2. 실제로 중복되지 않는지 검사한다.
  ///    2-1. 문제가 없다면 : 생성된 voteId와 wallet address, user 식별자를 묶어서 저장한다.
  ///    2-2. 문제가 있다면 : 다른 voteId를 생성한다.
  /// 3. voteId를 리턴한다.
  function makeUniqueVoteId(address walletId, string calldata identifier) private returns(string memory) {
    /// 1. 중복되지 않는 voteId를 생성한다.
    string memory _voteId = _uuid4();

    /// 2. identifier - walletId를 묶어서 저장함.
    mapUserIdWalletAddress[identifier] = walletId;

    /// 3. 생성된 voteId와 wallet address를 묶어서 저장한다.
    VoteIdData memory vd = VoteIdData(_voteId, true);
    mapWalletAddressVoteId[walletId] = vd;
    
    /// 4. _voteId가 발급되었음을 저장한다.
    _voteIdIssued[_voteId] = true;

    /// 5. voteId를 리턴한다.
    return _voteId;
  }
  function makeUniqueVoteId2(address walletId) private returns(string memory) {
    /// 1. 중복되지 않는 voteId를 생성한다.
    string memory _voteId = _uuid4();

    /// 2. 생성된 voteId와 wallet address를 묶어서 저장한다.
    mapWalletAddressVoteId[walletId].voteId = _voteId;
    mapWalletAddressVoteId[walletId].isExist = true;

    /// 3. _voteId가 발급되었음을 저장한다.
    _voteIdIssued[_voteId] = true;

    /// 4. voteId를 리턴한다.
    return _voteId;
  }

  /// uuid를 생성하는 내부 함수.
  function _uuid4() private view returns (string memory) {
    return Utils.bytesToString(_uuidGen());
  }

  /// @notice Generate UUID
  /// @return UUID of 16bytes
  function _uuidGen() private view returns (bytes memory) {
    bytes1[16] memory seventhByteMembers = [bytes1(0x40), bytes1(0x41), bytes1(0x42), bytes1(0x43), bytes1(0x44),bytes1(0x45),bytes1(0x46),bytes1(0x47),bytes1(0x48),bytes1(0x49),bytes1(0x4a),bytes1(0x4b),bytes1(0x4c),bytes1(0x4d),bytes1(0x4e),bytes1(0x4f)];
    bytes16 uuidData = bytes16(
      keccak256(
        abi.encodePacked(
          msg.sender,
          _uuidSeed ^ (block.timestamp + 16)
        )
      )
    );
    
    bytes memory uuid = abi.encodePacked(uuidData);
    uuid[6] = seventhByteMembers[(block.timestamp+16)/2%16];
    return uuid;
  }

  /**
  * @notice Store latest result/error
  * @param requestId The request ID, returned by sendRequest()
  * @param response Aggregated response from the user code
  * @param err Aggregated error from the user code or from the execution pipeline
  * Either response or error parameter will be set, but never both
  */
  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) internal override {
    if(_lastRequestIdVerifyUser == requestId) {
      _lastResponseVerifyUser = response;
      _lastErrorVerifyUser = err;

      _apiStatusVerifyUser[requestId] = APICallStatus.finished;
      emit ResponseVerifyUser(requestId, _lastResponseVerifyUser, _lastErrorVerifyUser);
    }

    else {
      revert UnexpectedRequestID(requestId);
    }
  }
}