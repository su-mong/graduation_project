// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UserIdentificationType, VoteState} from "./utils/Enums.sol";
import {VoteIdBaseContract} from "./vote_id/VoteIdBaseContract.sol";
import {VoteMetadataBaseContract} from "./vote_metadata/VoteMetadataBaseContract.sol";
import {DeadlineIsUp, ExceededWeightPerUser, NotValidVoteId, NotValidOptionName} from "./utils/Errors.sol";
import {BigNumbers} from "./library/BigNumbers.sol";
import {Utils} from "./utils/Utils.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

abstract contract VoteBaseContract is VoteIdBaseContract, VoteMetadataBaseContract, AutomationCompatibleInterface {
    using BigNumbers for *;
    using Utils for *;

    //1. 큰틀: 투표아이디 -> 전번 매핑 및 구조체, 전번 -> 선택지. 즉 아이디로 전번 전번으로 선택지.
    // 수정: 전화번호 check는 수몽선배 단에서 완료하여 보내니, vote Id와 선택지만 맵핑
    // 수정(10/18) : voteID : (투표 선택지 - 가중치) 로 맵핑
    // 수정(10/21) by sumong : 선택지에 대한 메타데이터 추가 -> 이로 인해 선택지이름(name)을 선택지id(uint32)로 변경
    struct Option {
        string name; // 선택지이름
        uint256 weight; // 가중치
    }

    /// 투표 가능 여부
    VoteState public voteState = VoteState.ongoing;
    /// 투표를 마감시킬 시각에 대한 timestamp(GMT 기준)
    uint public immutable deadline;

    /// 투표 선택지(이후 투표 과정에서 유효한 선택지인지를 체크하기 위한 용도)
    mapping(string => bool) private optionNames;

    /// 유저 한 명이 사용 가능한 가중치
    /// ex) givingWeightPerUser가 6이라면, 유저 한 명은 이 투표에서 최대 6까지의 가중치를 사용할 수 있다.
    uint256 public givingWeightPerUser;
    /// 투표한 기록이 있는 모든 voteId
    string[] private voteIdFinished;
    /// voteId별로 현재까지 투표에 사용한 가중치(weight)를 기록함.
    /// 1021 수정 : string[] 에서 mapping으로 변경(기존에는 투표를 마친 voteId를 기록했다.)
    mapping(string => uint256) private usingWeightPerUser;
    
    /// 각 voteId - 선택지 매핑
    mapping(string => Option[]) private voteOptions;

    /// option name - total weight 매핑
    /// (option별 최종 투표 결과 매핑)
    /// TODO : 이걸 public으로 공개하는 게 가능할듯?
    mapping (string => uint256) private totalWeight;

    constructor(
        /// @dev params of VoteIdBaseContract
        address router,
        UserIdentificationType identificationType,
        uint uuidSeed,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 jobId,
        string memory verifyUserIdentifierCallJavascriptSource,
        
        /// @dev params of VoteRecordBaseContract
        string[] memory _optionSet,
        uint256 _givingWeightPerUser,
        uint voteEndYear,
        uint voteEndMonth, 
        uint voteEndDay, 
        uint voteEndHour, 
        uint voteEndMinute, 
        uint voteEndSecond
    ) VoteIdBaseContract(router, identificationType, uuidSeed, subscriptionId, gasLimit, jobId, verifyUserIdentifierCallJavascriptSource) {
        /// 유저 한 명이 사용 가능한 가중치 설정
        givingWeightPerUser = _givingWeightPerUser;

        /// 투표 선택지 저장
        for (uint256 i = 0; i < _optionSet.length; i++) {
            optionNames[_optionSet[i]] = true;
        }

        /// 마감시간 저장
        deadline = Utils.toTimestamp(voteEndYear, voteEndMonth, voteEndDay, voteEndHour, voteEndMinute, voteEndSecond);
    }

    /// @return vote metadata of options (recommend json type)
    function callOptionsMetadata() public view virtual override returns (string memory);

    /// @notice Send user's selection to blockchain.
    /// @dev This works by adding weights to voting options.
    /// @param voteId: user's voteId
    /// @param optionName: user-selected option name
    /// @param optionWeight: weight assigned to the option by the user
    function addOption(string calldata voteId, string calldata optionName, uint256 optionWeight) internal {
        if(voteState != VoteState.ongoing) {
            revert DeadlineIsUp();
        } else if(checkVoteIdIsValid(voteId) == false) {
            revert NotValidVoteId(voteId);
        } else if(_checkOptionIsValid(optionName) == false) {
            revert NotValidOptionName(optionName);
        } else if(usingWeightPerUser[voteId] + optionWeight > givingWeightPerUser) {
            revert ExceededWeightPerUser(voteId);
        } else {
            Option memory newOption = Option(optionName, optionWeight);

            voteOptions[voteId].push(newOption);
            
            if(usingWeightPerUser[voteId] == 0) {
                voteIdFinished.push(voteId);
            }

            usingWeightPerUser[voteId] += optionWeight;
        }
    }

    /// @notice Get user's all selection information recorded to blockchain.
    /// @param voteId: user's voteId
    /// @return Option name + Weight that user gave.
    // 이 함수 사전 요구 조건 : 검증 컨트랙트에서 투표 ID를 정상 검증 한 경우만.
    // 투표 아이디와 전화번호를 사용하여 선택한 옵션을 반환하는 함수
    // 특정 투표 선택지의 정보를 가져오는 함수 
    // 선택지 명 + 가중치 전부 반환.
    function getUserOption(string calldata voteId) internal view returns (Option[] memory) {
        if(checkVoteIdIsValid(voteId) == false) {
            revert NotValidVoteId(voteId);
        }

        return voteOptions[voteId];
    }

    /// @notice Functions that obtain information for specific option.
    /// @dev This is for the purpose of showing the results of the vote. So it works normally only after the vote has been closed.
    /// @return totalweight: sum of option's weight
    function getTotalWeight(string calldata optionName) internal view returns(uint256) {
        if(_checkOptionIsValid(optionName) == false) {
            revert NotValidOptionName(optionName);
        }

        return totalWeight[optionName]; // 최종 합 리턴.
    }

    /// @dev Chainlink Automation function
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = block.timestamp > deadline;
    }

    /// @dev Chainlink Automation function
    function performUpkeep(bytes calldata) external override {
        // We highly recommend revalidating the upkeep in the performUpkeep function
        if (block.timestamp > deadline) {
            voteState = VoteState.calculatingResult;
            _runSummation();
        }
    }

    // 일단 private로 가정하고 sum 함수 짜보기
    // 오라클에 의해 call 할 함수
    // 입력값없고 리턴 없음.
    function _runSummation() private {
        for (uint256 i = 0; i < voteIdFinished.length; i++) {
            string memory _voteId = voteIdFinished[i];

            if(checkVoteIdIsValid(_voteId) == true) {
                for (uint256 j = 0; j < voteOptions[_voteId].length; j++) {
                    _summationOption(voteOptions[_voteId][j].name, voteOptions[_voteId][j].weight);
                }
            }
        }

        voteState = VoteState.finished;
    }

    // 투표 선택지에 가중치를 추가 하는 함수
    // 전제 조건 : 모든 옵션 네임이 토탈 웨이트에 사전 선언되어있어야함.
    // totalSet() 사전에 call 하기.
    function _summationOption(string memory optionName, uint256 optionWeight) private {
        if(_checkOptionIsValid(optionName) == true) {
            totalWeight[optionName] += optionWeight;
        }
    }

    /// @dev used for vote process
    function _checkOptionIsValid(string memory optionName) private view returns(bool) {
        return optionNames[optionName];
    }
}