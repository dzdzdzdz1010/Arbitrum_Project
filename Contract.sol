// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Import ERC20 interface
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RFID_IC is ERC20{
    address public tokenAddress; // Address of the ERC20 token
    uint256 public rewardAmount; // Amount of tokens to reward for every 1000 pesos spent

    mapping(address => uint256) public userEarned; //Mapping to track top Earners
    mapping(address => uint256) public userSpending; // Mapping to track user spending

    // Event to log spending and reward issuance
    event SpendingAndReward(address indexed user, uint256 amountSpent, uint256 tokensEarned);
    event UserRegistered(bytes32 hexcode, uint256 tokenbalance);

    constructor(uint256 _rewardAmount) ERC20("Pamasahe Token", "FARE"){
        rewardAmount = _rewardAmount;
    }

    //Creaeting the UserInfo Structure
    struct UserInfo {
        address walletAddress;
        uint256 tokenBalance;
        bool exists;
        bool withWallet;
    }

    //Hexcode Mapper to UserInfo
    mapping(bytes32 => UserInfo) public userData;
    //We use bytes32 to store Hexcode Strings

    function setUserData(bytes32 hexCode) public {
        UserInfo storage info = userData[hexCode];
        if (userData[hexCode].exists) {
            revert('RFID already registered');
        }
        info.tokenBalance = 0;
        info.exists = true;
        emit UserRegistered(hexCode, info.tokenBalance);
    }

    function BindWallet(bytes32 hexCode) public {
        if (isRegistered(hexCode)) {
            revert('User has existing wallet.');
        } if (!userData[hexCode].exists) {
            revert("RFID isn't registered");
        }
        userData[hexCode].walletAddress = msg.sender;
        userData[hexCode].tokenBalance = balanceOf(msg.sender);
        userData[hexCode].withWallet = true;
    }
    //function to get UserData

    function getUserData(bytes32 hexCode) public view returns (address, uint256) {
        UserInfo memory info = userData[hexCode];
        return (info.walletAddress, info.tokenBalance);
    }

    function getUserWallet(bytes32 hexCode) public view returns (address) {
        UserInfo memory info = userData[hexCode];
        return info.walletAddress;
    }

    function getUserTokenBalance(bytes32 hexCode) public view returns (uint256) {
        UserInfo memory info = userData[hexCode];
        if (!isRegistered(hexCode)) {
            revert('No wallet connected for this RFID.');
        }
        return balanceOf(userData[hexCode].walletAddress);
    }

    function RFID_Scanned(bytes32 hexCode) public {
        if (userData[hexCode].exists) {
            // if user is registered, returns user data
            getUserData(hexCode);
        } else {
            // if user is not registered, register it.
            setUserData(hexCode);
        }
    }
    //checks if user has registered its wallet.
    function isRegistered(bytes32 hexCode) public view returns(bool) {
        return userData[hexCode].withWallet;
    }


    // Function to allow users to spend and earn rewards
    function spendAndEarn(bytes32 hexCode, uint256 _amountSpent) external {
        // Assume 1 ether = 1000 pesos for simplicity
        bool isReg = isRegistered(hexCode);
        require(isReg = true, "Bind your wallet to your RFID card first!");

        uint256 amountInToken = _amountSpent / 100;

        // Update user spending
        // can be used for creating top spenders leaderboards
        userSpending[userData[hexCode].walletAddress] += _amountSpent;
        

        // Calculate reward tokens
        uint256 tokensEarned = amountInToken * rewardAmount;
        userEarned[userData[hexCode].walletAddress] += tokensEarned;

        // Transfer tokens to user
        _mint(userData[hexCode].walletAddress, tokensEarned*10**18);
        userData[hexCode].tokenBalance = balanceOf(userData[hexCode].walletAddress);

        // Emit event
        emit SpendingAndReward(msg.sender, _amountSpent, tokensEarned);
    }
}