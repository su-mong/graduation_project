// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UserIdentificationType} from "graduation_project_library/utils/Enums.sol";
import {ApiCallNotFinishedYet} from "graduation_project_library/utils/Errors.sol";
import {VoteBaseContract} from "graduation_project_library/VoteBaseContract.sol";
import {VoteMetadata} from "graduation_project_example/VoteMetadata.sol";

contract ESportsVoteExample is VoteBaseContract {
  // 유저 인증 타입.
  UserIdentificationType constant _identificationType = UserIdentificationType.phone;
  // on-chain router.
  address constant _router = 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C;
  // uuid 생성에 쓰임. random semiprime number with 256 bits.
  uint constant _seed = 98686309634733686614376257523655700182914516739573612855898430044873713577331;
  uint64 constant _subscriptionId = 393;
  uint32 constant _gasLimit = 300000;
  bytes32 constant _jobId = 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000;

  /// @dev params of VoteRecordBaseContract
  uint256 constant _givingWeightPerUser = 6;
  
  // vote metadata array
  // ["Chovy","Faker","Bdd","Zeka","Showmaker","Clozer","BuLLDoG","Karis","FATE","FIESTA"]
  VoteMetadata[10] private _metadata;

  // 생성자
  constructor(string[] memory _optionSet) VoteBaseContract(
    _router, 
    _identificationType, 
    _seed, 
    _subscriptionId, 
    _gasLimit,
    _jobId, 
    _verifyUserIdentifierSource,

    _optionSet,
    _givingWeightPerUser,
    2023,
    10,
    22,
    7,
    0,
    0
  ) {
    // insert vote metadata
    _metadata[0] = VoteMetadata(
      "FFAB8A00",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_chovy.png", 
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_chovy.png",
      "Chovy",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_geng.png",
      "GEN",
      "0.6"
    );
    _metadata[1] = VoteMetadata(
      "FFE4002C",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_faker.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_faker.png",
      "Faker",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_t1.png",
      "T1",
      "0.5"
    );
    _metadata[2] = VoteMetadata(
      "FFFF0806",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_bdd.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_bdd.png",
      "Bdd",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_kt.png",
      "KT",
      "0.5"
    );
    _metadata[3] = VoteMetadata(
      "FFFF6C02",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_zeka.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_zeka.png",
      "Zeka",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_hanwha.png",
      "HLE",
      "0.6"
    );
    _metadata[4] = VoteMetadata(
      "FFE3EE84",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_showmaker.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_showmaker.png",
      "Showmaker",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_dplus.png",
      "DK",
      "0.5"
    );
    _metadata[5] = VoteMetadata(
      "FFFFC900",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_closer.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_closer.png",
      "Clozer",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_sandbox.png",
      "LSB",
      "0.5"
    );
    _metadata[6] = VoteMetadata(
      "FFE73312",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_bulldog.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_bulldog.png",
      "BuLLDoG",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_kwangdong.png",
      "KDF",
      "0.6"
    );
    _metadata[7] = VoteMetadata(
      "FF01492B",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_karis.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_karis.png",
      "Karis",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_brion.png",
      "BRO",
      "0.6"
    );
    _metadata[8] = VoteMetadata(
      "FF1002A3",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_fate.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_fate.png",
      "FATE",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_drx.png",
      "DRX",
      "0.6"
    );
    _metadata[9] = VoteMetadata(
      "FFDF2027",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/s_fiesta.png",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/l_fiesta.png",
      "FIESTA",
      "https://raw.githubusercontent.com/su-mong/graduation_project_backend_server/main/images/t_nongshim.png",
      "NS",
      "0.6"
    );
  }

  /// @return vote metadata (recommend json type)
  function callOptionsMetadata() public override view returns (string memory) {
    string memory result = "{\"data\": [";

    for(uint i = 0; i < _metadata.length; i++) {
      result = appendString(result, "{\"smallProfileUrl\": \"", _metadata[i].smallProfileUrl);
      result = appendString(result, "\",\"bigProfileUrl\": \"", _metadata[i].bigProfileUrl);
      result = appendString(result, "\",\"name\": \"", _metadata[i].name);
      result = appendString(result, "\",\"teamLogoUrl\": \"", _metadata[i].teamLogoUrl);
      result = appendString(result, "\",\"teamName\": \"", _metadata[i].teamName);
      result = appendString(result, "\",\"mainColor\": \"", _metadata[i].mainColor);
      result = appendString(result, "\",\"teamSelectingBackgroundOpacityPercent\": ", _metadata[i].teamSelectingBackgroundOpacity);

      if(i == _metadata.length - 1) {
        result = appendString(result, "}", "");
      } else {
        result = appendString(result, "},", "");
      }
    }

    result = appendString(result, "]}", "");

    return result;
  }

  function showUserVoteId() public view returns(string memory) {
    return showVoteId(0x943844f20785721635dCeB4689f6b475EA99feCf);
  }

  function issueVoteId(string calldata phoneNumber) public returns(string memory) {
    return issueVoteIdByPhone(phoneNumber, 0x943844f20785721635dCeB4689f6b475EA99feCf);
  }

  /*function issueVoteId(string calldata phoneNumber, address walletId) public returns(string memory) {
    return issueVoteIdByPhone(phoneNumber, walletId);
  }*/

  function selectFirst(string calldata voteId, string calldata first, string calldata second, string calldata third) public {
    addOption(voteId, first, 3);
    addOption(voteId, second, 2);
    addOption(voteId, third, 1);
  }

  function getUserVoteRecord(string calldata voteId) public view returns (string memory) {
    Option[] memory _userSelection = getUserOption(voteId);
    string memory result = "{";

    for(uint i = 0; i < _userSelection.length; i++) {
      if(_userSelection[i].weight == 3) {
        result = appendString(result, "\"first\": \"", _userSelection[i].name);
        
        if(i == _userSelection.length - 1) {
          result = appendString(result, "\"}", "");
        } else {
          result = appendString(result, "\",", "");
        }
      } else if(_userSelection[i].weight == 2) {
        result = appendString(result, "\"second\": \"", _userSelection[i].name);
        
        if(i == _userSelection.length - 1) {
          result = appendString(result, "\"}", "");
        } else {
          result = appendString(result, "\",", "");
        }
      } else if(_userSelection[i].weight == 1) {
        result = appendString(result, "\"third\": \"", _userSelection[i].name);
        
        if(i == _userSelection.length - 1) {
          result = appendString(result, "\"}", "");
        } else {
          result = appendString(result, "\",", "");
        }
      }
    }

    return result;
  }

  function getVoteResultPerOption(string calldata optionName) public view returns(uint256) {
    return getTotalWeight(optionName);
  }

  /// sendVerificationCode에 쓰이는 request javascript
  string constant _verifyUserIdentifierSource = "const phoneNumber = args[0];\n"
    "const code = args[1];\n"
    "const url = \"http://49.50.162.41:3097/auth/validate_code\";\n"
    "const verificationRequest = Functions.makeHttpRequest({\n"
    "  url: url,\n"
    "  method: \"POST\",\n"
    "  headers: {\n"
    "    \"Content-Type\": \"application/json\",\n"
    "    \"accept\": \"application/json\"\n"
    "  },\n"
    "  data: {\n"
    "    \"phone\": phoneNumber,\n"
    "    \"code\": code\n"
    "  },\n"
    "});\n"
    "const authRequestCodeResponse = await verificationRequest;\n"
    "if (authRequestCodeResponse.error) {\n"
    "  console.error(\n"
    "    authRequestCodeResponse.response\n"
    "      ? `${authRequestCodeResponse.response.status},${authRequestCodeResponse.response.statusText}`\n"
    "      : \"\"\n"
    "  );\n"
    "  throw Error(\"Request failed\");\n"
    "}\n"
    "const authRequestResult = authRequestCodeResponse[\"data\"];\n"
    "if (!authRequestResult) { //  || !authRequestResult.isCreated\n"
    "  throw Error(`Error : cannot translate response`);\n"
    "}\n"
    "const result = {\n"
    "  phone: phoneNumber,\n"
    "  isCorrect: authRequestResult.isCorrect,\n"
    "};\n"
    "return Functions.encodeString(JSON.stringify(result));\n";
}
