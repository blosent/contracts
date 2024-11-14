// SPDX-License-Identifier: MIT
// SPDX-FileContributor: Bakhankov Anton (blosent.com)

pragma solidity 0.8.27;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract Schedule {
    bool public enabled;
    uint256 public nextPaymentTimestamp;
    address payable public owner;
    address public recipient;
    address public token;
    uint256 public amount;
    uint64 public interval;
    uint256 public incentive;
    uint256 public incentiveLocked;
    mapping (address => uint256) public incentiveLockedMap;

    event PaymentEvent(address executor, uint256 timestamp);

    constructor(address _recipient, address _token, uint256 _amount, uint256 _firstPayAt, uint64 _interval, uint256 _incentive, address payable _owner) payable {
        require(_recipient != address(0), "Invalid recipient address");
        require(_token != address(0), "Token can't be the zero address");
        require(_amount != 0, "Amount can't be zero");
        require(_interval != 0, "Interval can't be zero");

        nextPaymentTimestamp = _firstPayAt;
        owner = _owner;
        recipient = _recipient;
        token = _token;
        amount = _amount;
        interval = _interval;
        incentive = _incentive;
        enabled = true;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert("Ownable: caller is not the owner");
        }
        _;
    }

    function enable() external onlyOwner {
        require(!enabled, "Schedule is already enabled");
        enabled = true;
    }

    function disable() external onlyOwner {
        require(enabled, "Schedule is already disabled");
        enabled = false;
    }

    function withdraw() external onlyOwner {
        address self = address(this);
        IERC20 erc20 = IERC20(token);
        if (erc20.balanceOf(self) > 0) {
            erc20.transfer(owner, erc20.balanceOf(self));
        }
        if (ethBalance() > 0) {
            owner.transfer(ethBalance());
        }
    }

    function pay() external {
        require(enabled, "Schedule is disabled");
        require(nextPaymentTimestamp < block.timestamp, "It's not time to pay yet");
        require(ethBalance() >= incentive, "Low eth balance");

        nextPaymentTimestamp = block.timestamp + interval;
        incentiveLockedMap[msg.sender] += incentive;
        incentiveLocked += incentive;

        require(IERC20(token).transfer(recipient, amount), "Failed to transfer tokens");

        emit PaymentEvent(msg.sender, block.timestamp);
    }

    function ethBalance() public view returns (uint256) {
        return address(this).balance - incentiveLocked;
    }

    function incentivize() external {
        uint256 lockedIncentive = incentiveLockedMap[msg.sender];
        require(lockedIncentive != 0, "No locked incentive");
        incentiveLockedMap[msg.sender] = 0;
        incentiveLocked -= lockedIncentive;
        payable(msg.sender).transfer(lockedIncentive);
    }

    receive() external payable {}
}
