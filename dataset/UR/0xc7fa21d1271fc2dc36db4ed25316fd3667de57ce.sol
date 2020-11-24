 

pragma solidity ^0.4.24;

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

interface IOneInchTrade {

    function getRateFromKyber(IERC20 from, IERC20 to, uint amount) external view returns (uint expectedRate, uint slippageRate);
    function getRateFromBancor(IERC20 from, IERC20 to, uint amount) external view returns (uint conversionAmount, uint conversionFee);
}

 

interface KyberNetworkProxy {

    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty)
    external view
    returns (uint expectedRate, uint slippageRate);
}

 

interface BancorConverter {

    function getReturn(IERC20 _fromToken, IERC20 _toToken, uint256 _amount) external view returns (uint256, uint256);
}

 

 
contract OneInchTrade is IOneInchTrade {

    uint constant MIN_TRADING_AMOUNT = 0.0001 ether;

    KyberNetworkProxy public kyberNetworkProxy;
    BancorConverter public bancorConverter;

    address public daiTokenAddress;
    address public daiBntTokenAddress;
    address public bntTokenAddress;

    address constant public KYBER_ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant public BANCOR_ETHER_ADDRESS = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;

    event Trade(
        uint indexed _type,
        uint indexed _amount,
        uint indexed _network
    );

    event TradeResult(
        uint indexed _amount
    );

    constructor(
        address kyberNetworkProxyAddress,
        address bancorConverterAddress,
        address bntAddress
    ) public {

        kyberNetworkProxy = KyberNetworkProxy(kyberNetworkProxyAddress);
        bancorConverter = BancorConverter(bancorConverterAddress);
        bntTokenAddress = bntAddress;
    }

    function getRateFromKyber(IERC20 from, IERC20 to, uint amount) public view returns (uint expectedRate, uint slippageRate) {

        return kyberNetworkProxy.getExpectedRate(
            from,
            to,
            amount
        );
    }

    function getRateFromBancor(IERC20 from, IERC20 to, uint amount) public view returns (uint expectedRate, uint slippageRate) {

        return bancorConverter.getReturn(
            from,
            to,
            amount
        );
    }

    function() external payable {

        uint startGas = gasleft();

        require(msg.value >= MIN_TRADING_AMOUNT, "Min trading amount not reached.");

        IERC20 daiToken = IERC20(daiTokenAddress);
        IERC20 daiBntToken = IERC20(daiBntTokenAddress);

        (uint kyberExpectedRate, uint kyberSlippageRate) = getRateFromKyber(
            IERC20(KYBER_ETHER_ADDRESS),
            IERC20(bntTokenAddress),
            msg.value
        );

        (uint bancorBNTConversionAmount, uint bancorBNTConversionFee) = getRateFromBancor(
            IERC20(BANCOR_ETHER_ADDRESS),
            IERC20(bntTokenAddress),
            msg.value
        );

         
         
         
         
         
         
         
         
         
         
         

        uint kyberTradingAmount = kyberExpectedRate * msg.value;
        uint bancorTradingAmount = bancorBNTConversionAmount + bancorBNTConversionFee;

        uint tradedResult = 0;

        if (kyberTradingAmount > bancorTradingAmount) {

             
            tradedResult = kyberTradingAmount - bancorTradingAmount;

            emit Trade(0, bancorTradingAmount, 1);
            emit Trade(1, kyberTradingAmount, 0);
        } else {

             
            tradedResult = bancorTradingAmount - kyberTradingAmount;

            emit Trade(0, kyberTradingAmount, 0);
            emit Trade(1, bancorTradingAmount, 1);
        }


        emit TradeResult(tradedResult);

        msg.sender.transfer(msg.value);
 
 
 
 

         
         
    }
}