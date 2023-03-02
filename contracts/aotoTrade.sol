pragma solidity >=0.5.6;
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMath for uint256;

    /**
     * @dev 排序token地址
     * @notice 返回排序的令牌地址，用于处理按此顺序排序的对中的返回值
     * @param tokenA TokenA
     * @param tokenB TokenB
     * @return token0  Token0
     * @return token1  Token1
     */
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        //确认tokenA不等于tokenB
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        //排序token地址
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        //确认token地址不等于0地址
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /**
     * @dev 获取pair合约地址
     * @notice 计算一对的CREATE2地址，而无需进行任何外部调用
     * @param factory 工厂地址
     * @param tokenA TokenA
     * @param tokenB TokenB
     * @return pair  pair合约地址
     */
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        //排序token地址
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        //根据排序的token地址计算create2的pair地址
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        // pair合约bytecode的keccak256
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                    )
                )
            )
        );
    }

    /**
     * @dev 获取储备
     * @notice 提取并排序一对的储备金
     * @param factory 工厂地址
     * @param tokenA TokenA
     * @param tokenB TokenB
     * @return reserveA  储备量A
     * @return reserveB  储备量B
     */
    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        //排序token地址
        (address token0, ) = sortTokens(tokenA, tokenB);
        //通过排序后的token地址和工厂合约地址获取到pair合约地址,并从pair合约中获取储备量0,1
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc).getReserves();
        //根据输入的token顺序返回储备量
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /**
     * @dev 对价计算
     * @notice 给定一定数量的资产和货币对储备金，则返回等值的其他资产
     * @param amountA 数额A
     * @param reserveA 储备量A
     * @param reserveB 储备量B
     * @return amounts  数额B
     */
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset

    /**
     * @dev 获取单个输出数额
     * @notice 给定一项资产的输入量和配对的储备，返回另一项资产的最大输出量
     * @param amountIn 输入数额
     * @param reserveIn 储备量In
     * @param reserveOut 储备量Out
     * @return amounts  输出数额
     */
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        //确认输入数额大于0
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        //确认储备量In和储备量Out大于0
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        //税后输入数额 = 输入数额 * 997
        uint256 amountInWithFee = amountIn.mul(997);
        //分子 = 税后输入数额 * 储备量Out
        uint256 numerator = amountInWithFee.mul(reserveOut);
        //分母 = 储备量In * 1000 + 税后输入数额
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        //输出数额 = 分子 / 分母
        amountOut = numerator / denominator;
    }

    /**
     * @dev 获取单个输出数额
     * @notice 给定一项资产的输出量和对储备，返回其他资产的所需输入量
     * @param amountOut 输出数额
     * @param reserveIn 储备量In
     * @param reserveOut 储备量Out
     * @return amounts  输入数额
     */
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        //确认输出数额大于0
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        //确认储备量In和储备量Out大于0
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        //分子 = 储备量In * 储备量Out * 1000
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        //分母 = 储备量Out - 输出数额 * 997
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        //输入数额 = (分子 / 分母) + 1
        amountIn = (numerator / denominator).add(1);
    }

  
}


// 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a
interface IUniswapV2Router01 {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

}

contract AutoTrade{

    address private owner = address(msg.sender);
    IUniswapV2Pair private pairAddress = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
    IERC20 usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);  // token0
    IERC20 wethToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  // token1
    IUniswapV2Router01 Router01 = IUniswapV2Router01(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);
    // 查询usd余额
    function getUsdBalanceOF() external view returns(uint){
        return usdcToken.balanceOf(address(this));
    }

    // 查询weth余额
    function getWethBalanceOF() external view returns(uint){
        return wethToken.balanceOf(address(this));
    }

    // 得到某一个货币对应的另一种货币金额
    function GetAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }
    
    // pair合约得到储备量,这是测试排过序的
    function getReserves(
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        ( reserveA, reserveB, ) = IUniswapV2Pair(address(pairAddress)).getReserves();
        
        return (reserveA, reserveB);
    }
    
    // 自动通过swap交易
    function AotoSwap(uint amountIn, uint amountOutMin, address[] calldata path) external {
        // address[] memory path = address[](0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        Router01.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 600);
        // swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external
    }
}
