 

 

pragma solidity 0.5.3;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

contract KyberNetworkProxyInterface {
  function swapEtherToToken(IERC20 token, uint minConversionRate) public payable returns (uint);
  function swapTokenToToken(IERC20 src, uint srcAmount, IERC20 dest, uint minConversionRate) public returns (uint);
}

contract PaymentsLayer {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;   
  IERC20 public dai = IERC20(DAI_ADDRESS);

  address public constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  event PaymentForwarded(address indexed from, address indexed to, address indexed srcToken, uint256 amountDai, uint256 amountSrc, uint256 changeDai, bytes encodedFunctionCall);

  function forwardEth(KyberNetworkProxyInterface _kyberNetworkProxy, IERC20 _srcToken, uint256 _minimumRate, address _destinationAddress, bytes memory _encodedFunctionCall) public payable {
    require(address(_srcToken) != address(0) && _minimumRate > 0 && _destinationAddress != address(0), "invalid parameter(s)");

    uint256 srcQuantity = address(_srcToken) == ETH_TOKEN_ADDRESS ? msg.value : _srcToken.allowance(msg.sender, address(this));

    if (address(_srcToken) != ETH_TOKEN_ADDRESS) {
      _srcToken.safeTransferFrom(msg.sender, address(this), srcQuantity);

      require(_srcToken.allowance(address(this), address(_kyberNetworkProxy)) == 0, "non-zero initial _kyberNetworkProxy allowance");
      require(_srcToken.approve(address(_kyberNetworkProxy), srcQuantity), "approving _kyberNetworkProxy failed");
    }

    uint256 amountDai = address(_srcToken) == ETH_TOKEN_ADDRESS ? _kyberNetworkProxy.swapEtherToToken.value(srcQuantity)(dai, _minimumRate) : _kyberNetworkProxy.swapTokenToToken(_srcToken, srcQuantity, dai, _minimumRate);
    require(amountDai >= srcQuantity.mul(_minimumRate).div(1e18), "_kyberNetworkProxy failed");

    require(dai.allowance(address(this), _destinationAddress) == 0, "non-zero initial destination allowance");
    require(dai.approve(_destinationAddress, amountDai), "approving destination failed");

    (bool success, ) = _destinationAddress.call(_encodedFunctionCall);
    require(success, "destination call failed");

    uint256 changeDai = dai.allowance(address(this), _destinationAddress);
    if (changeDai > 0) {
      dai.safeTransfer(msg.sender, changeDai);
      require(dai.approve(_destinationAddress, 0), "un-approving destination failed");
    }

    emit PaymentForwarded(msg.sender, _destinationAddress, address(_srcToken), amountDai.sub(changeDai), srcQuantity, changeDai, _encodedFunctionCall);
  }
}