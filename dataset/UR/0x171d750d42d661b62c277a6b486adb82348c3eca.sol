 

pragma solidity 0.4.19;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
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

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint64 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract EcomToken is BurnableToken, Owned {
    string public constant name = "Omnitude Token";
    string public constant symbol = "ECOM";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 100000000 * 10**uint256(decimals);

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 55000000 * 10**uint256(decimals);

     
    address public omniTeamAddress;

     
    address public foundationAddress;

     
    address public year1LockAddress;

     
    address public year2LockAddress;

     
    address public year3LockAddress;

     
    address public year4LockAddress;

     
    address public year5LockAddress;

     
    uint64 private constant date01Jan2019 = 1546300800;

     
    uint64 private constant date01Jan2020 = 1577836800;

     
    uint64 private constant date01Jan2021 = 1609459200;

     
    uint64 private constant date01Jan2022 = 1640995200;

     
    uint64 private constant date01Jan2023 = 1672531200;

     
    bool public tokenSaleClosed = false;

     
    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP && !tokenSaleClosed);
        _;
    }

     
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    function EcomToken(address _omniTeamAddress, address _foundationAddress) public {
        require(_omniTeamAddress != address(0));
        require(_foundationAddress != address(0));

        omniTeamAddress = _omniTeamAddress;
        foundationAddress = _foundationAddress;
        totalSupply = TOKENS_SALE_HARD_CAP;
        balances[owner] = TOKENS_SALE_HARD_CAP;
    }

     
    function close() public onlyOwner beforeEnd {
         
        uint256 saleTokensToBurn = balances[owner];
        balances[owner] = 0;
        totalSupply = totalSupply.sub(saleTokensToBurn);
        Burn(owner, saleTokensToBurn);

         
        uint256 foundationTokens = 33000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(foundationTokens);
        balances[foundationAddress] = foundationTokens;

         
        uint256 teamTokens = 12000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(teamTokens);

         
        uint256 teamTokensY1 = 2400000 * 10**uint256(decimals);
         
        TokenTimelock year1Lock = new TokenTimelock(this, omniTeamAddress, date01Jan2019);
        year1LockAddress = address(year1Lock);
        balances[year1LockAddress] = teamTokensY1;

         
        uint256 teamTokensY2 = 2400000 * 10**uint256(decimals);
         
        TokenTimelock year2Lock = new TokenTimelock(this, omniTeamAddress, date01Jan2020);
        year2LockAddress = address(year2Lock);
        balances[year2LockAddress] = teamTokensY2;

         
        uint256 teamTokensY3 = 2400000 * 10**uint256(decimals);
         
        TokenTimelock year3Lock = new TokenTimelock(this, omniTeamAddress, date01Jan2021);
        year3LockAddress = address(year3Lock);
        balances[year3LockAddress] = teamTokensY3;

         
        uint256 teamTokensY4 = 2400000 * 10**uint256(decimals);
         
        TokenTimelock year4Lock = new TokenTimelock(this, omniTeamAddress, date01Jan2022);
        year4LockAddress = address(year4Lock);
        balances[year4LockAddress] = teamTokensY4;

         
        uint256 teamTokensY5 = 2400000 * 10**uint256(decimals);
         
        TokenTimelock year5Lock = new TokenTimelock(this, omniTeamAddress, date01Jan2023);
        year5LockAddress = address(year5Lock);
        balances[year5LockAddress] = teamTokensY5;

        tokenSaleClosed = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(msg.sender != owner && !tokenSaleClosed) return false;
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(msg.sender != owner && !tokenSaleClosed) return false;
        return super.transfer(_to, _value);
    }
}