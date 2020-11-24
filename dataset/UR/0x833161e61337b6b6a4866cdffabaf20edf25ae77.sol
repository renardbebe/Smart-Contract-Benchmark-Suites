 

pragma solidity ^0.4.15;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    
    
}



contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferByInternal(address from, address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MintedToken(address indexed target, uint256 value);
}

contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 maxSupply_;
    uint256 totalSupply_;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    } 

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function maxSupply() public view returns (uint256) {
        return maxSupply_;
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferByInternal(address _from, address _to, uint256 _value) internal returns (bool) {
         
        require(_to != address(0));
         
        require(_value > 0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint256 previousBalances = balances[_from] + balances[_to];
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public {
        require(_target != address(0));
        require(_mintedAmount > 0);
        require(maxSupply_ > 0 && totalSupply_.add(_mintedAmount) <= maxSupply_);
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply_ = totalSupply_.add(_mintedAmount);
        Transfer(0, _target, _mintedAmount);
        MintedToken(_target, _mintedAmount);
    }
}

contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
  }
}



contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract CBS is StandardToken, CanReclaimToken {
    using SafeMath for uint;

    event BuyToken(address indexed from, uint256 value);
    event SellToken(address indexed from, uint256 value, uint256 sellEth);
    event TransferContractEth(address indexed to, uint256 value);


    string public symbol;
    string public name;
    string public version = "2.0";

    uint8 public decimals;
    uint256 INITIAL_SUPPLY;
    uint256 tokens;

    uint256 public buyPrice;
    uint256 public sellPrice;
    uint256 public contractEth;
    bool public allowBuy;
    bool public allowSell;

     
    function CBS(
        string _symbol,
        string _name,
        uint8 _decimals, 
        uint256 _INITIAL_SUPPLY,
        uint256 _buyPrice,
        uint256 _sellPrice,
        bool _allowBuy,
        bool _allowSell
    ) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        INITIAL_SUPPLY = _INITIAL_SUPPLY * 10 ** uint256(decimals);
        setBuyPrices(_buyPrice);
        setSellPrices(_sellPrice);

        totalSupply_ = INITIAL_SUPPLY;
        maxSupply_ = INITIAL_SUPPLY;
        balances[owner] = totalSupply_;
        allowBuy = _allowBuy;
        allowSell = _allowSell;
    }

    function setAllowBuy(bool _allowBuy) public onlyOwner {
        allowBuy = _allowBuy;
    }

    function setBuyPrices(uint256 _newBuyPrice) public onlyOwner {
        buyPrice = _newBuyPrice;
    }

    function setAllowSell(bool _allowSell) public onlyOwner {
        allowSell = _allowSell;
    }

    function setSellPrices(uint256 _newSellPrice) public onlyOwner {
        sellPrice = _newSellPrice;
    }

    function () public payable {
        BuyTokens(msg.value);
    }

    function BuyTokens(uint256 _value)  internal {
        tokens = _value.div(buyPrice).mul(100);
        require(allowBuy);
        require(_value > 0 && _value >= buyPrice && tokens > 0);
        require(balances[owner] >= tokens);

        super.transferByInternal(owner, msg.sender, tokens);
        contractEth = contractEth.add(_value);
        BuyToken(msg.sender, _value);
    }

    function transferEther(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_value <= contractEth);
        _to.transfer(_value);
        contractEth = contractEth.sub(_value);
        TransferContractEth(_to, _value);
        return true;
    }

    

    function sellTokens(uint256 _value) public returns (bool) {
        uint256 sellEth;
        require(allowSell);
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        if (sellPrice == 0){
            sellEth = 0;
        }
        else
        {
            sellEth = _value.mul(sellPrice).div(100);
        }

        super.transferByInternal(msg.sender, owner, _value);
        SellToken(msg.sender, _value, sellEth);
        msg.sender.transfer(sellEth);
        contractEth = contractEth.sub(sellEth);
    }

}