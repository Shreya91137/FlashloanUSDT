// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Aave V3 interfaces
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlashLoanUSDT
 * @notice A contract to execute a 100,000 USDT flash loan on Aave V3
 */
contract FlashLoanUSDT {
    // Aave's PoolAddressesProvider for Ethereum Mainnet
    IPoolAddressesProvider public immutable provider;
    // Aave Lending Pool
    IPool public immutable pool;

    // Contract owner
    address public owner;

    // USDT contract address (Ethereum Mainnet)
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /**
     * @dev Constructor sets the Aave PoolAddressesProvider
     */
    constructor(address _addressesProvider) {
        owner = msg.sender;
        provider = IPoolAddressesProvider(_addressesProvider);
        pool = IPool(provider.getPool());
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /**
     * @notice Allows owner to deposit USDT into the contract
     */
    function deposit(uint256 amount) external onlyOwner {
        require(IERC20(USDT).transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    /**
     * @notice Allows owner to withdraw USDT from the contract
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(IERC20(USDT).transfer(msg.sender, amount), "Transfer failed");
    }

    /**
     * @notice Executes a flash loan of *100,000 USDT* from Aave
     */
    function executeFlashLoan() external onlyOwner {
        uint256 amount = 100000 * 1e6; // 100,000 USDT (6 decimals)
        address receiver = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        // Borrow USDT from Aave Pool
        pool.flashLoanSimple(receiver, USDT, amount, params, referralCode);
    }

    /**
     * @notice Function called by Aave after sending the flash loan
     * @dev You must repay the loan before this function completes
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata /* params */
    ) external returns (bool) {
        require(asset == USDT, "Unexpected asset");
        require(initiator == address(this), "Unexpected initiator");

        // 1️⃣ Add profit-making logic here (arbitrage, liquidation, etc.)

        // 2️⃣ Repay the flash loan (borrowed amount + Aave fee)
        uint256 totalDebt = amount + premium;
        IERC20(USDT).approve(address(pool), totalDebt);

        return true;
    }
}