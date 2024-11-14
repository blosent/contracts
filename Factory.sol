// SPDX-License-Identifier: MIT
// SPDX-FileContributor: Bakhankov Anton (blosent.com)

pragma solidity ^0.8.27;

import "./Schedule.sol";

contract Factory {
    uint256 public incentive;

    event ScheduleCreatedEvent(address indexed owner, address scheduleAddress);

    constructor(uint256 _incentive) {
        incentive = _incentive;
    }

    function createSchedule(address recipient, address token, uint256 amount, uint256 firstPayAt, uint64 interval) public {
        Schedule schedule = new Schedule(recipient, token, amount, firstPayAt, interval, incentive, payable(msg.sender));
        emit ScheduleCreatedEvent(msg.sender, address(schedule));
    }
}
