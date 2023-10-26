// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice User authentication type. Used to specify which type of authentication is used to obtain the noteId.
enum UserIdentificationType {
    phone,
    wallet
}

/// @notice API processing status
enum APICallStatus {
    notYet,
    loading,
    finished
}

/// @notice Vote state
enum VoteState {
    notStarted, // Vote is not started yet.
    ongoing, // User can vote.
    calculatingResult, // Vote is finished, and contract is calculating the result.
    finished // Vote is finished, and user can see the result.
}