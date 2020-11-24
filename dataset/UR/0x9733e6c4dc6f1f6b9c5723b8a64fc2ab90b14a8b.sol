 

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

 
contract Ownable
{
    address owner;

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

interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract TokenERC20 is Ownable
{
    using SafeMath for uint;

     
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint256 public buyPrice = 1000000000000000000 wei;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply.mul(DEC);   
        balanceOf[this] = totalSupply;          
        avaliableSupply = balanceOf[this];      
        name = tokenName;                       
        symbol = tokenSymbol;                   
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal
    {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);

        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);      

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
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
        require(balanceOf[msg.sender] >= _value);    

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       
        avaliableSupply = avaliableSupply.sub(_value);

        Burn(msg.sender, _value);

        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     

        balanceOf[_from] = balanceOf[_from].sub(_value);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);     
        totalSupply = totalSupply.sub(_value);               
        avaliableSupply = avaliableSupply.sub(_value);

        Burn(_from, _value);

        return true;
    }
}

contract Pauseble is TokenERC20
{
    event EPause();
    event EUnpause();

    bool public paused = true;
    uint public startIcoDate = 0;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause();
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause();
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause();
    }
}

contract ERC20Extending is TokenERC20
{
    using SafeMath for uint;

     
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        _to.transfer(amount);
    }

     
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {
        avaliableSupply = avaliableSupply.sub(_value);
        _transfer(this, _to, _value);
    }
}

contract StreamityCrowdsale is Pauseble
{
    using SafeMath for uint;

    uint public stage = 0;
    uint256 public weisRaised;   

    event CrowdSaleFinished(string info);

    struct Ico {
        uint256 tokens;              
        uint startDate;              
        uint endDate;                
        uint8 discount;              
        uint8 discountFirstDayICO;   
    }

    Ico public ICO;

     
    function confirmSell(uint256 _amount) internal view
        returns(bool)
    {
        if (ICO.tokens < _amount) {
            return false;
        }

        return true;
    }

     
    function countDiscount(uint256 amount) internal
        returns(uint256)
    {
        uint256 _amount = (amount.mul(DEC)).div(buyPrice);

        if (1 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (2 == stage)
        {
            if (now <= ICO.startDate + 1 days)
            {
                if (0 == ICO.discountFirstDayICO) {
                    ICO.discountFirstDayICO = 20;
                }
                _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
            }
            else
            {
                _amount = _amount.add(withDiscount(_amount, ICO.discount));
            }
        }
        else if (3 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }

        return _amount;
    }

     
    function changeDiscount(uint8 _discount) public onlyOwner
        returns (bool)
    {
        ICO = Ico (ICO.tokens, ICO.startDate, ICO.endDate, _discount, ICO.discountFirstDayICO);
        return true;
    }

     
    function changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
        returns (bool success)
    {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator.mul(DEC)).div(_denominator);

        return true;
    }

     
    function crowdSaleStatus() internal constant
        returns (string)
    {
        if (1 == stage) {
            return "Pre-ICO";
        } else if(2 == stage) {
            return "ICO first stage";
        } else if (3 == stage) {
            return "ICO second stage";
        } else if (4 >= stage) {
            return "feature stage";
        }

        return "there is no stage at present";
    }

     
    function paymentManager(address sender, uint256 value) internal
    {
        uint256 discountValue = countDiscount(value);
        bool conf = confirmSell(discountValue);

        if (conf) {

            sell(sender, discountValue);

            weisRaised = weisRaised.add(value);

            if (now >= ICO.endDate) {
                pauseInternal();
                CrowdSaleFinished(crowdSaleStatus());  
            }

        } else {

            sell(sender, ICO.tokens);  

            weisRaised = weisRaised.add(value);

            pauseInternal();
            CrowdSaleFinished(crowdSaleStatus());   
        }
    }

     
    function sell(address _investor, uint256 _amount) internal
    {
        ICO.tokens = ICO.tokens.sub(_amount);
        avaliableSupply = avaliableSupply.sub(_amount);

        _transfer(this, _investor, _amount);
    }

     
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO) public onlyOwner
    {
        require(_tokens * DEC <= avaliableSupply);   
        ICO = Ico (_tokens * DEC, _startDate, _startDate + _endDate * 1 days , _discount, _discountFirstDayICO);
        stage = stage.add(1);
        unpauseInternal();
    }

     
    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }

     
    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }
}

contract StreamityContract is ERC20Extending, StreamityCrowdsale
{
     
    function StreamityContract() public TokenERC20(186000000, "Streamity", "STM") {}  

     
    function () public payable
    {
        assert(msg.value >= 1 ether / 10);
        require(now >= ICO.startDate);

        if (paused == false) {
            paymentManager(msg.sender, msg.value);
        } else {
            revert();
        }
    }
}