 

pragma solidity ^0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    address public addressFundTeam = 0x0DA34504b759071605f89BE43b2804b1869404f2;
    uint256 public fundTeam = 1125 * 10**4 * (10 ** 18);
    uint256 endTimeIco = 1551535200;  

     
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);
        if (msg.sender == addressFundTeam) {
            require(checkVesting(_value, now) > 0);
        }

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function checkVesting(uint256 _value, uint256 _currentTime) public view returns(uint8 period) {
        period = 0;
        require(endTimeIco <= _currentTime);
        if (endTimeIco + 26 weeks <= _currentTime && _currentTime < endTimeIco + 52 weeks) {
            period = 1;
            require(balances[addressFundTeam].sub(_value) >= fundTeam.mul(95).div(100));
        }
        if (endTimeIco + 52 weeks <= _currentTime && _currentTime < endTimeIco + 78 weeks) {
            period = 2;
            require(balances[addressFundTeam].sub(_value) >= fundTeam.mul(85).div(100));
        }
        if (endTimeIco + 78 weeks <= _currentTime && _currentTime < endTimeIco + 104 weeks) {
            period = 3;
            require(balances[addressFundTeam].sub(_value) >= fundTeam.mul(65).div(100));
        }
        if (endTimeIco + 104 weeks <= _currentTime && _currentTime < endTimeIco + 130 weeks) {
            period = 4;
            require(balances[addressFundTeam].sub(_value) >= fundTeam.mul(35).div(100));
        }
        if (endTimeIco + 130 weeks <= _currentTime) {
            period = 5;
            require(balances[addressFundTeam].sub(_value) >= 0);
        }
    }
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
contract Ownable {
    address public owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


 

contract CryptoCasherToken is StandardToken, Ownable {
    string public constant name = "CryptoCasher";
    string public constant symbol = "CRR";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 75 * 10**6 * (10 ** uint256(decimals));

    uint256 fundForSale = 525 * 10**5 * (10 ** uint256(decimals));

    address addressFundAdvisors = 0xee3b4F0A6EA27cCDA45f2F58982EA54c5d7E8570;
    uint256 fundAdvisors = 6 * 10**6 * (10 ** uint256(decimals));

    address addressFundBounty = 0x97133480b61377A93dF382BebDFC3025D56bA2C6;
    uint256 fundBounty = 375 * 10**4 * (10 ** uint256(decimals));

    address addressFundBlchainReferal = 0x2F9092Fe1dACafF1165b080BfF3afFa6165e339a;
    uint256 fundBlchainReferal = 75 * 10**4 * (10 ** uint256(decimals));

    address addressFundWebSiteReferal = 0x45E2203eD8bD3888D052F4CF37ac91CF6563789D;
    uint256 fundWebSiteReferal = 75 * 10**4 * (10 ** uint256(decimals));

    address addressContract;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event AddressContractChanged(address indexed addressContract, address indexed sender);


constructor (address _owner) public
    {
        require(_owner != address(0));
        owner = _owner;
         
        transfersEnabled = true;
        distribToken(owner);
        totalSupply = INITIAL_SUPPLY;
    }

     
    function setContractAddress(address _contract) public onlyOwner {
        require(_contract != address(0));
        addressContract = _contract;
        emit AddressContractChanged(_contract, msg.sender);
    }

    modifier onlyContract() {
        require(msg.sender == addressContract);
        _;
    }
     
    function mint(address _to, uint256 _amount, address _owner) external onlyContract returns (bool) {
        require(_to != address(0) && _owner != address(0));
        require(_amount <= balances[_owner]);
        require(transfersEnabled);

        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

     
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        CryptoCasherToken token = CryptoCasherToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit Transfer(_token, owner, balance);
    }

    function distribToken(address _wallet) internal {
        require(_wallet != address(0));

        balances[addressFundAdvisors] = balances[addressFundAdvisors].add(fundAdvisors);

        balances[addressFundTeam] = balances[addressFundTeam].add(fundTeam);

        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        balances[addressFundBlchainReferal] = balances[addressFundBlchainReferal].add(fundBlchainReferal);
        balances[addressFundWebSiteReferal] = balances[addressFundWebSiteReferal].add(fundWebSiteReferal);

        balances[_wallet] = balances[_wallet].add(fundForSale);
    }

     
    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(_value <= totalSupply);
        require(_value <= fundForSale);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}