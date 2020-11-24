 

 

pragma solidity ^0.5.2;

 
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

contract KyberNetworkProxyInterface {
  function swapEtherToToken(IERC20 token, uint minConversionRate) public payable returns(uint);
}

contract PaymentsLayer {
  using SafeMath for uint256;

  address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;   
  IERC20 public dai = IERC20(DAI_ADDRESS);

  address public constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  IERC20 public eth = IERC20(ETH_TOKEN_ADDRESS);

  event PaymentForwarded(address indexed from, address indexed to, uint256 amountEth, uint256 amountDai, bytes encodedFunctionCall);

  function forwardEth(KyberNetworkProxyInterface _kyberNetworkProxy, uint256 _minimumRate, address _destinationAddress, bytes memory _encodedFunctionCall) public payable {
    require(msg.value > 0 && _minimumRate > 0 && _destinationAddress != address(0), "invalid parameter(s)");

    uint256 amountDai = _kyberNetworkProxy.swapEtherToToken.value(msg.value)(dai, _minimumRate);
    require(amountDai >= msg.value.mul(_minimumRate), "_kyberNetworkProxy failed");

    require(dai.allowance(address(this), _destinationAddress) == 0, "non-zero initial destination allowance");
    require(dai.approve(_destinationAddress, amountDai), "approving destination failed");

    (bool success, ) = _destinationAddress.call(_encodedFunctionCall);
    require(success, "destination call failed");
    require(dai.allowance(address(this), _destinationAddress) == 0, "allowance not fully consumed by destination");

    emit PaymentForwarded(msg.sender, _destinationAddress, msg.value, amountDai, _encodedFunctionCall);
  }
}