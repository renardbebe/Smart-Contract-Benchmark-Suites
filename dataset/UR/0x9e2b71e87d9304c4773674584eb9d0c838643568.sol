 

pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Pausable is owned {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


contract TokenERC20 is Pausable {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
     
    uint256 public TokenForSale;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 TokenSale
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        TokenForSale =  TokenSale * 10 ** uint256(decimals);

    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] =  allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract Sale is owned, TokenERC20 {

     
    uint256 public soldTokens;

    modifier CheckSaleStatus() {
        require (TokenForSale >= soldTokens);
        _;
    }

}


contract Shopiblock is TokenERC20, Sale {
    using SafeMath for uint256;
    uint256 public  unitsOneEthCanBuy;
    uint256 public  minPurchaseQty;

    mapping (address => bool) public airdrops;


     
    function Shopiblock()
    TokenERC20(1000000000, 'Shopiblock', 'SHB', 100000) public {
        unitsOneEthCanBuy = 80000;
        soldTokens = 0;
        minPurchaseQty = 16000 * 10 ** uint256(decimals);
    }

    function changeOwnerWithTokens(address newOwner) onlyOwner public {
        uint previousBalances = balanceOf[owner] + balanceOf[newOwner];
        balanceOf[newOwner] += balanceOf[owner];
        balanceOf[owner] = 0;
        assert(balanceOf[owner] + balanceOf[newOwner] == previousBalances);
        owner = newOwner;
    }

    function changePrice(uint256 _newAmount) onlyOwner public {
        unitsOneEthCanBuy = _newAmount;
    }

    function startSale() onlyOwner public {
        soldTokens = 0;
    }

    function increaseSaleLimit(uint256 TokenSale)  onlyOwner public {
        TokenForSale = TokenSale * 10 ** uint256(decimals);
    }

    function increaseMinPurchaseQty(uint256 newQty) onlyOwner public {
        minPurchaseQty = newQty * 10 ** uint256(decimals);
    }
    
    function airDrop(address[] _recipient, uint _totalTokensToDistribute) onlyOwner public {
        uint256 total_token_to_transfer = (_totalTokensToDistribute * 10 ** uint256(decimals)).mul(_recipient.length); 
        require(balanceOf[owner] >=  total_token_to_transfer);
        for(uint256 i = 0; i< _recipient.length; i++)
        {
            if (!airdrops[_recipient[i]]) {
              airdrops[_recipient[i]] = true;
              _transfer(owner, _recipient[i], _totalTokensToDistribute * 10 ** uint256(decimals));
            }
        }
    }
    function() public payable whenNotPaused CheckSaleStatus {
        uint256 eth_amount = msg.value;
        uint256 amount = eth_amount.mul(unitsOneEthCanBuy);
        soldTokens = soldTokens.add(amount);
        require(amount >= minPurchaseQty );
        require(balanceOf[owner] >= amount );
        _transfer(owner, msg.sender, amount);
         
        owner.transfer(msg.value);
    }
}