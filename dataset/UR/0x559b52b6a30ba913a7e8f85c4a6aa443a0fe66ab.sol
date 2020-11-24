 

pragma solidity ^0.4.0;

 

contract ERC20Constant {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance(address owner, address spender) constant returns (uint _allowance);
}
contract ERC20Stateful {
    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
}
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}
contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
 

contract TokenTrader is owned {

    address public asset;        
    uint256 public buyPrice;    
    uint256 public sellPrice;   
    uint256 public units;        

    bool public sellsTokens;     
    bool public buysTokens;      

    event ActivatedEvent(bool sells, bool buys);
    event UpdateEvent();

    function TokenTrader (
        address _asset, 
        uint256 _buyPrice, 
        uint256 _sellPrice, 
        uint256 _units,
        bool    _sellsTokens,
        bool    _buysTokens
        )
    {
          asset         = _asset; 
          buyPrice     = _buyPrice; 
          sellPrice    = _sellPrice;
          units         = _units; 
          sellsTokens   = _sellsTokens;
          buysTokens    = _buysTokens;

          ActivatedEvent(sellsTokens,buysTokens);
    }

     
    function activate (
        bool    _sellsTokens,
        bool    _buysTokens
        )
    {
          sellsTokens   = _sellsTokens;
          buysTokens    = _buysTokens;

          ActivatedEvent(sellsTokens,buysTokens);
    }

     
     
     
    function deposit() payable onlyOwner {
    }

     
    function withdrawAsset(uint256 _value) onlyOwner returns (bool ok)
    {
        return ERC20(asset).transfer(owner,_value);
    }

     
     
    function withdrawToken(address _token, uint256 _value) onlyOwner returns (bool ok)
    {
        return ERC20(_token).transfer(owner,_value);
    }

     
    function withdraw(uint256 _value) onlyOwner returns (bool ok)
    {
        if(this.balance >= _value) {
            return owner.send(_value);
        }
    }

     
    function buy() payable {
        if(sellsTokens || msg.sender == owner) 
        {
            uint order   = msg.value / sellPrice; 
            uint can_sell = ERC20(asset).balanceOf(address(this)) / units;

            if(order > can_sell)
            {
                uint256 change = msg.value - (can_sell * sellPrice);
                order = can_sell;
                if(!msg.sender.send(change)) throw;
            }

            if(order > 0) {
                if(!ERC20(asset).transfer(msg.sender,order * units)) throw;
            }
            UpdateEvent();
        }
        else throw;   
    }

     
     
    function sell(uint256 amount) {
        if (buysTokens || msg.sender == owner) {
            uint256 can_buy = this.balance / buyPrice;   
            uint256 order = amount / units;              

            if(order > can_buy) order = can_buy;         

            if (order > 0)
            { 
                 
                if(!ERC20(asset).transferFrom(msg.sender, address(this), amount)) throw;

                 
                if(!msg.sender.send(order * buyPrice)) throw;
            }
            UpdateEvent();
        }
    }

     
    function () payable {
        buy();
    }
}

 
 

contract TokenTraderFactory {

    event TradeListing(bytes32 bookid, address owner, address addr);
    event NewBook(bytes32 bookid, address asset, uint256 units);

    mapping( address => bool ) public verify;
    mapping( bytes32 => bool ) pairExits;

    function createTradeContract(       
        address _asset, 
        uint256 _buyPrice, 
        uint256 _sellPrice, 
        uint256 _units,
        bool    _sellsTokens,
        bool    _buysTokens
        ) returns (address) 
    {
        if(_buyPrice > _sellPrice) throw;  
        if(_units == 0) throw;               

        address trader = new TokenTrader (
                     _asset, 
                     _buyPrice, 
                     _sellPrice, 
                     _units,
                     _sellsTokens,
                     _buysTokens);

        var bookid = sha3(_asset,_units);

        verify[trader] = true;  

        TokenTrader(trader).transferOwnership(msg.sender);  

        if(pairExits[bookid] == false) {
            pairExits[bookid] = true;
            NewBook(bookid, _asset, _units);
        }

        TradeListing(bookid,msg.sender,trader);
    }

    function () {
        throw;      
    }
}