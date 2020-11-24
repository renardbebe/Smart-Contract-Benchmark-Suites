 

pragma solidity ^0.4.18;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract OwnableToken
{
    address owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function OwnableToken() public {
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


interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

 
contract ERC20 is OwnableToken
{
    using SafeMath for uint;

    uint256 constant MAX_UINT256 = 2**256 - 1;

     
    string public name;
    string public symbol;
    uint256 public decimals = 8;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public totalSupply;
    uint256 public price = 0 wei;

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply.mul(DEC);   
        balances[msg.sender] = totalSupply;          
        name = tokenName;                       
        symbol = tokenSymbol;                   
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal
    {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to].add(_value) > balances[_to]);
         
        uint previousBalances = balances[_from].add(balances[_to]);
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
         
        assert(balances[_from].add(balances[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _holder) view public
        returns (uint256 balance)
    {
        return balances[_holder];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);      

        if (allowance[_from][msg.sender] < MAX_UINT256) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        _transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;
        }
    }

     
    function increaseApproval (address _spender, uint _addedValue) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        returns (bool success)
    {
        uint oldValue = allowance[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

     
    function burn(uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);    

        balances[msg.sender] = balances[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       

        Burn(msg.sender, _value);

        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     

        balances[_from] = balances[_from].sub(_value);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);     
        totalSupply = totalSupply.sub(_value);               

        Burn(_from, _value);

        return true;
    }
}

contract PausebleToken is ERC20
{
    event EPause(address indexed owner, string indexed text);
    event EUnpause(address indexed owner, string indexed text);

    bool public paused = true;

    modifier isPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause(owner, 'sale is paused');
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause(owner, 'sale is paused');
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause(owner, 'sale is unpaused');
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause(owner, 'sale is unpaused');
    }
}

contract ERC20Extending is ERC20
{
    using SafeMath for uint;

     
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        _to.transfer(amount);
    }

     
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {
        _transfer(this, _to, _value);
    }
}

contract CrowdsaleContract is PausebleToken
{
    using SafeMath for uint;

    uint256 public receivedEther;   

    event CrowdSaleFinished(address indexed owner, string indexed text);

    struct sale {
        uint256 tokens;    
        uint startDate;    
        uint endDate;      
    }

    sale public Sales;

    uint8 public discount;   

     
    function confirmSell(uint256 _amount) internal view
        returns(bool)
    {
        if (Sales.tokens < _amount) {
            return false;
        }

        return true;
    }

     
    function countDiscount(uint256 amount) internal view
        returns(uint256)
    {
        uint256 _amount = (amount.mul(DEC)).div(price);
        _amount = _amount.add(withDiscount(_amount, discount));

        return _amount;
    }

     
    function changeDiscount(uint8 _discount) public onlyOwner
        returns (bool)
    {
        discount = _discount;
        return true;
    }

     
    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }

     
    function changePrice(uint256 _price) public onlyOwner
        returns (bool success)
    {
        require(_price != 0);
        price = _price;
        return true;
    }

     
    function paymentManager(uint256 value) internal
    {
        uint256 _value = (value * 10 ** uint256(decimals)) / 10 ** uint256(18);
        uint256 discountValue = countDiscount(_value);
        bool conf = confirmSell(discountValue);

         

        if (conf) {

            Sales.tokens = Sales.tokens.sub(_value);
            receivedEther = receivedEther.add(value);

            if (now >= Sales.endDate) {
                pauseInternal();
                CrowdSaleFinished(owner, 'crowdsale is finished');
            }

        } else {

            Sales.tokens = Sales.tokens.sub(Sales.tokens);
            receivedEther = receivedEther.add(value);

            pauseInternal();
            CrowdSaleFinished(owner, 'crowdsale is finished');
        }
    }

    function transfertWDiscount(address _spender, uint256 amount) public onlyOwner
        returns(bool)
    {
        uint256 _amount = (amount.mul(DEC)).div(price);
        _amount = _amount.add(withDiscount(_amount, discount));
        transfer(_spender, _amount);

        return true;
    }

     
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate) public onlyOwner
    {
        Sales = sale (_tokens * DEC, _startDate, _startDate + _endDate * 1 days);
        unpauseInternal();
    }

}

contract TokenContract is ERC20Extending, CrowdsaleContract
{
     
    function TokenContract() public
        ERC20(10000000000, "Debit Coin", "DEBC") {}

     
    function () public payable
    {
        assert(msg.value >= 1 ether / 100);
        require(now >= Sales.startDate);

        if (paused == false) {
            paymentManager(msg.value);
        } else {
            revert();
        }
    }
}