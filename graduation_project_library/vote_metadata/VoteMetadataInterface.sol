// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface VoteMetadataInterface {
    /// @return vote metadata (recommend json type)
    function callOptionsMetadata() external view returns (string memory);
}