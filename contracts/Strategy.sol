//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { ICurve } from "./interfaces/ICurve.sol";
import { IYearn } from "./interfaces/IYearn.sol";
import "hardhat/console.sol";

contract Strategy {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStETH;

    IStETH internal immutable stETH;
    ICurve internal immutable crvPool;
    IERC20 internal immutable crvLP;
    IYearn internal immutable yvault;

    mapping(address => uint256) public investments;

    event Invested(uint256 indexed amount, address indexed user);
    event Disinvested(uint256 indexed amount, address indexed user);

    error No_ETH_Supplied();
    error Insufficient_Amount_Invested();

    constructor(
        address _stETH,
        address _crvPool,
        address _crvLP,
        address _yvault
    ) {
        stETH = IStETH(_stETH);
        crvPool = ICurve(_crvPool);
        crvLP = IERC20(_crvLP);
        yvault = IYearn(_yvault);

        stETH.safeApprove(address(crvPool), type(uint256).max);
        crvLP.safeApprove(address(yvault), type(uint256).max);
    }

    function invest(uint256 amount) external payable {
        if(msg.value == 0) revert No_ETH_Supplied();
        if(msg.value != amount) revert Insufficient_Amount_Invested();
        
        // stake ETH on Lido and get stETH
        uint256 shares = stETH.submit{ value: amount }(address(this));

        // Deposit the stETH on Curve stETH-ETH pool
        // The returned stETH amount may be lower of 1 wei, we check the correct return value using shares computation
        uint256 lpTokenAmount = crvPool.add_liquidity([uint256(0), stETH.getPooledEthByShares(shares)], block.timestamp + 5 minutes); 
        ///^ in a real world scenario you may want to provide the deadline off-chain

        // Deposit Curve LP tokens on Yearn
        investments[msg.sender] += yvault.deposit(lpTokenAmount, address(this));

        emit Invested(amount, msg.sender);
    }

    function disinvest() external {
        if(investments[msg.sender] == 0) revert Insufficient_Amount_Invested();

        uint256 amount = investments[msg.sender];
        delete investments[msg.sender]; // avoid reentrancy

        // Unstake crvstETH from Yearn
        uint256 crvstETHamount = yvault.withdraw(amount, address(this), 1);

        console.log(crvstETHamount);

        // Remove liquidity from Curve
        uint256 minAmount = crvPool.calc_token_amount([uint256(0), crvstETHamount], false);
        uint256 amountOut = crvPool.remove_liquidity_one_coin(crvstETHamount, 0, minAmount);

        payable(msg.sender).transfer(amountOut);

        emit Disinvested(amountOut, msg.sender);
    }
}
