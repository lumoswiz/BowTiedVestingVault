// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Counters} from "openzeppelin-contracts/utils/Counters.sol";

struct VestingDetails {
    address token;
    uint256 amount;
    bool claimed;
}

contract VestingVault is Ownable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------
    using Counters for Counters.Counter;
    Counters.Counter public fundCount;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error Error_VaultAlreadyFunded();
    error Error_InvalidTimeRange();
    error Error_MismatchedTokensAndAmounts();
    error Error_ZeroAmount();
    error Error_VestingNotOver();
    error Error_ExceedsMaxVestingDuration();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    uint256 internal constant MAX_VESTING_DURATION = 1460 days; // 4 years

    address public beneficiary;

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    VestingDetails[] public vestingDetails;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "notBeneficiary");
        _;
    }

    constructor(address _beneficiary) {
        beneficiary = _beneficiary;
        startTimestamp = block.timestamp;
    }

    function fund(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _endTimestamp
    ) external onlyOwner {
        if (fundCount.current() != 0) revert Error_VaultAlreadyFunded();

        if (_tokens.length != _amounts.length)
            revert Error_MismatchedTokensAndAmounts();

        if (_endTimestamp <= startTimestamp) revert Error_InvalidTimeRange();

        if (_endTimestamp - startTimestamp > MAX_VESTING_DURATION)
            revert Error_ExceedsMaxVestingDuration();

        for (uint256 i; i < _tokens.length; ++i) {
            if (_amounts[i] == 0) revert Error_ZeroAmount();

            vestingDetails.push(
                VestingDetails({
                    token: _tokens[i],
                    amount: _amounts[i],
                    claimed: false
                })
            );

            IERC20(_tokens[i]).transferFrom(
                msg.sender,
                address(this),
                _amounts[i]
            );
        }

        // Set unlockTime of vault
        endTimestamp = _endTimestamp;
    }

    function withdraw() external onlyBeneficiary {
        if (block.timestamp < endTimestamp) revert Error_VestingNotOver();

        for (uint256 i; i < vestingDetails.length; ++i) {
            if (vestingDetails[i].claimed == false) {
                vestingDetails[i].claimed = true;
                IERC20(vestingDetails[i].token).transfer(
                    beneficiary,
                    vestingDetails[i].amount
                );
            }
        }
    }
}
