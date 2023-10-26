// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VoteMetadataInterface} from "graduation_project_library/vote_metadata/VoteMetadataInterface.sol";

abstract contract VoteMetadataBaseContract is VoteMetadataInterface {
    /// @return vote metadata of options (recommend json type)
    function callOptionsMetadata() public view virtual returns (string memory);

    /// @notice String append method for making json output.
    function appendString(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
}

contract GGGGGGGGGGGG {
    address public addrM;

    function getAddress(address addr) public {
        addrM = addr;
    }
}