// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Definition here allows both the lib and inheriting contracts to use BigNumber directly.
struct BigNumber { 
    bytes val;
    bool neg;
    uint bitlen;
}

/**
 * @notice BigNumbers library for Solidity.
 */
library Utils {
    function bytesToString(bytes memory buffer) internal pure returns (string memory) {
        // Fixed buffer size for hexadecimal conversion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";
        uint i = 0;
        uint buffLength = buffer.length;
        for (i; i < buffLength; ++i) {
        converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
        converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked(converted));
    }

    // 시간값 time stamp 변환 로직
    function toTimestamp(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        require(year >= 1970, "Year must be 1970 or later");
        require(month > 0 && month <= 12, "Invalid month");
        require(day > 0 && day <= 31, "Invalid day");
        require(hour < 24, "Invalid hour");
        require(minute < 60, "Invalid minute");
        require(second < 60, "Invalid second");

        uint256 myTimestamp;
        myTimestamp += second;
        myTimestamp += minute * 60;
        myTimestamp += hour * 60 * 60;
        myTimestamp += (day - 1) * 24 * 60 * 60;
        for (uint i = 1970; i < year; i++) {
            if (isLeapYear(i)) {
                myTimestamp += 366 days;
            } else {
                myTimestamp += 365 days;
            }
        }
        for (uint i = 1; i < month; i++) {
            myTimestamp += daysInMonth(i, year) * 24 * 60 * 60;
        }
        return myTimestamp;
    }

    function isLeapYear(uint year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function daysInMonth(uint month, uint year) private pure returns (uint) {
        if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        }
        if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        return 31;
    }
}