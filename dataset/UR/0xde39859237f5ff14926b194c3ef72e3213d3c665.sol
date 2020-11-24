 

pragma solidity ^0.4.18;


 
library SafeMath {
  function mul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) pure internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
  }
}

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
      require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public;  
    function transferFrom(address _from, address _to, uint _value) public;  
    function approve(address _spender, uint _value) public;  
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract KyberNetworkContract {

     
     
     
     
     
     
     
     
     
     
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
    
     
     
     
     
     
    function findBestRate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint, uint);
}

interface KULAPTradingProxy {
     
    event Trade( ERC20 src, uint srcAmount, ERC20 dest, uint destAmount);

     
     
     
     
     
     
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest
    )
        public
        payable
        returns(uint);
    
    function rate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint, uint);
}

contract Dex is Ownable {
    event Trade( ERC20 src, uint srcAmount, ERC20 dest, uint destAmount);

    using SafeMath for uint256;
    ERC20 public etherERC20 = ERC20(0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    address public dexWallet = 0x7ff0F1919424F0D2B6A109E3139ae0f1d836D468;  

     
    KULAPTradingProxy[] public tradingProxies;

    function _tradeEtherToToken(uint256 tradingProxyIndex, uint256 srcAmount, ERC20 dest) private returns(uint256)  {
         
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

         
        uint256 destAmount = tradingProxy.trade.value(srcAmount)(
            etherERC20,
            srcAmount, 
            dest
        );

        return destAmount;
    }

     
    function () payable {

    }

    function _tradeTokenToEther(uint256 tradingProxyIndex, ERC20 src, uint256 amount) private returns(uint256)  {
         
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

         
        src.approve(tradingProxy, amount);

         
        uint256 destAmount = tradingProxy.trade(
            src, 
            amount, 
            etherERC20);
        
        return destAmount;
    }

     
     
     
     
     
    function _trade(uint256 tradingProxyIndex, ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount) private returns(uint256)  {
        uint256 destAmount;

         
        if (etherERC20 == src) {
            destAmount = _tradeEtherToToken(tradingProxyIndex, srcAmount, dest);
        
         
        } else if (etherERC20 == dest) {
            destAmount = _tradeTokenToEther(tradingProxyIndex, src, srcAmount);

         
        } else {

        }

         
        assert(destAmount >= minDestAmount);

        return destAmount;
    }

     
     
     
     
     
    function trade(uint256 tradingProxyIndex, ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount) payable public returns(uint256)  {
        uint256 destAmount;

         
        if (etherERC20 == src) {
            destAmount = _trade(tradingProxyIndex, src, srcAmount, dest, 1);

             
            assert(destAmount >= minDestAmount);

             
             
             
            dest.transfer(msg.sender, destAmount);
        
         
        } else if (etherERC20 == dest) {
             
            src.transferFrom(msg.sender, address(this), srcAmount);

            destAmount = _trade(tradingProxyIndex, src, srcAmount, dest, 1);

             
            assert(destAmount >= minDestAmount);

             
             
            msg.sender.send(destAmount);

         
        } else {

        }

        Trade( src, srcAmount, dest, destAmount);

        return destAmount;
    }

     
     
     

     
     
     
     
     
    function tradeRoutes(ERC20 src, uint256 srcAmount, ERC20 dest, uint256 minDestAmount, address[] _tradingPaths) payable public returns(uint256)  {
        uint256 destAmount;

        if (etherERC20 != src) {
             
            src.transferFrom(msg.sender, address(this), srcAmount);
        }

        uint256 pathSrcAmount = srcAmount;
        for (uint i=0; i < _tradingPaths.length; i+=3) {
            uint256 tradingProxyIndex =         uint256(_tradingPaths[i]);
            ERC20 pathSrc =                     ERC20(_tradingPaths[i+1]);
            ERC20 pathDest =                    ERC20(_tradingPaths[i+2]);

            destAmount = _trade(tradingProxyIndex, pathSrc, pathSrcAmount, pathDest, 1);
            pathSrcAmount = destAmount;
        }

         
        assert(destAmount >= minDestAmount);

         
        if (etherERC20 == dest) {
             
             
            msg.sender.send(destAmount);
        
         
        } else {
             
             
             
            dest.transfer(msg.sender, destAmount);
        }

        Trade( src, srcAmount, dest, destAmount);

        return destAmount;
    }

     
     
     
     
     
     
     
    function rate(uint256 tradingProxyIndex, ERC20 src, ERC20 dest, uint srcAmount) public view returns(uint, uint) {
         
        KULAPTradingProxy tradingProxy = tradingProxies[tradingProxyIndex];

        return tradingProxy.rate(src, dest, srcAmount);
    }

     
    function addTradingProxy(
        KULAPTradingProxy _proxyAddress
    ) public onlyOwner returns (uint256) {

        tradingProxies.push( _proxyAddress );

        return tradingProxies.length;
    }
}