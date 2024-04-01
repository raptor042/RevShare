// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RevShare {
    address public owner;

    address public token;

    uint256 public pool;

    uint256 public minDeposit = 0.1 ether;

    uint256 public minBalance = 1000 ether;

    struct User {
        address user;
        uint256 balance;
        uint256 timestamp;
    }

    User[] public users;

    mapping (address => User) public user;

    mapping (address => bool) public eligible;

    constructor(address _token) {
        owner = msg.sender;

        token = _token;

        pool = 0;
    }

    event Pool_Funded(uint256 amount);

    event Eligibility(address indexed hodler);

    event User_Created(address indexed user);

    event Claimed(address indexed user, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function fundPool() public payable onlyOwner {
        require(msg.value >= minDeposit, "Minimium prize pool requirement is 1 ETH.");

        pool += msg.value;

        emit Pool_Funded(msg.value);
    }

    function changeMinDeposit(uint256 min_deposit) public onlyOwner {
        minDeposit = min_deposit * 1 ether;
    }

    function changeMinBalance(uint256 min_balance) public onlyOwner {
        minBalance = min_balance * 1 ether;
    }

    function make_eligible(address hodler) public onlyOwner {
        eligible[hodler] = true;

        emit Eligibility(hodler);
    }

    function userExists(address _user) internal view returns (bool) {
        bool user_exist = false;

        for(uint256 i = 0; i < users.length; i++) {
            if(users[i].user == _user) {
                user_exist = true;

                break;
            }
        }

        return user_exist;
    }

    function createUser(address user_) internal {
        User memory _user = User({
            user: user_,
            balance: 0,
            timestamp: block.timestamp
        });

        users.push(_user);

        user[user_] = _user;

        emit User_Created(user_);
    }

    function distribute() public onlyOwner {
        IERC20 Token = IERC20(token);

        uint256 supply = Token.totalSupply() / (10 ** Token.decimals());

        for(uint256 i = 0; i < users.length; i++) {
            User storage _user = users[i];

            uint256 balance = Token.balanceOf(_user.user) / (10 ** Token.decimals());

            if(Token.balanceOf(_user.user) >= minBalance) {
                uint256 dividend = (balance * pool) / supply;
                
                _user.balance += dividend;
            }
        }
    }

    function claim() public payable {
        require(pool > 0, "Prize pool is empty.");

        require(eligible[msg.sender], "You are not eligible to claim rewards.");

        IERC20 Token = IERC20(token);

        require(Token.balanceOf(msg.sender) >= minBalance, "You do not HODL enough of the token.");

        uint256 balance = Token.balanceOf(msg.sender) / (10 ** Token.decimals());

        uint256 supply = Token.totalSupply() / (10 ** Token.decimals());

        if(userExists(msg.sender)) {
            User storage _user = user[msg.sender];

            uint256 duration = _user.timestamp - block.timestamp;

            require(duration >= 86400, "Please wait for the next share unlock.");

            uint256 dividend = (balance * pool) / supply;

            (bool os, ) = payable(msg.sender).call{value: dividend}("");
            require(os);

            pool -= dividend;

            _user.balance -= dividend;

            _user.timestamp = block.timestamp;

            emit Claimed(msg.sender, dividend);
        } else {
            createUser(msg.sender);

            uint256 dividend = (balance * pool) / supply;

            (bool os, ) = payable(msg.sender).call{value: dividend}("");
            require(os);

            pool -= dividend;

            emit Claimed(msg.sender, dividend);
        }
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);

        pool = 0;
    }
}
