// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Error Type : fulfillRequest function gets wrong requestId parameter.
error UnexpectedRequestID(bytes32 requestId);

/// @notice Error Type : API Call is not finished yet
error ApiCallNotFinishedYet(bytes32 requestId);

/// @notice Error Type : wrong method call for UserIdentificationType
error WrongMethodForUserIdentificationType();

/// @notice Error Type : user identifier - wallet address not matching
error UserIdentifierWalletAddressNotMatching(string identifier);

/// @notice Error Type : Attempting to vote when the deadline is up
error DeadlineIsUp();

/// @notice Error Type : A particular user tries to vote more than the weight available for voting per person
error ExceededWeightPerUser(string voteId);

/// @notice Error Type : voteId is not valid
error NotValidVoteId(string voteId);

/// @notice Error Type : optionName is not valid
error NotValidOptionName(string optionName);