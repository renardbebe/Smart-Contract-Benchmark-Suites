 

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

contract MobilinkToken is BurnableToken, Owned {
    string public constant name = "Mobilink";
    string public constant symbol = "MOBL";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 9000000000 * 10**uint256(decimals);

     
    address public mobilinkTeamAddress;

     
    address public reserveAddress;

     
    address public teamTokensLockAddress;

     
    address public buildOutAddress;

     
    address public saleTokensVault;

     
    bool public stageOneClosed = false;

     
    bool public stageTwoClosed = false;

     
    modifier beforeStageOneClosed {
        require(!stageOneClosed && !stageTwoClosed);
        _;
    }

     
    modifier afterStageOneClosed {
        require(stageOneClosed && !stageTwoClosed);
        _;
    }

    function MobilinkToken(address _mobilinkTeamAddress, address _reserveAddress,
                           address _buildOutAddress, address _saleTokensVault) public {
        require(_mobilinkTeamAddress != address(0));
        require(_reserveAddress != address(0));
        require(_buildOutAddress != address(0));
        require(_saleTokensVault != address(0));

        mobilinkTeamAddress = _mobilinkTeamAddress;
        reserveAddress = _reserveAddress;
        buildOutAddress = _buildOutAddress;
        saleTokensVault = _saleTokensVault;

         
         
        uint256 saleTokens = 4140000000 * 10**uint256(decimals);
        totalSupply = saleTokens;
        balances[saleTokensVault] = saleTokens;

         
        uint256 reserveTokens = 2610000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(reserveTokens);
        balances[reserveAddress] = reserveTokens;

         
        uint256 buildOutTokens = 900000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(buildOutTokens);
        balances[buildOutAddress] = buildOutTokens;
    }

     
    function closeStageOne() public onlyOwner beforeStageOneClosed {
        stageOneClosed = true;
    }

     
    function closeStageTwo() public onlyOwner afterStageOneClosed {
        stageTwoClosed = true;
    }

     
     
    function lockTeamTokens() public onlyOwner afterStageOneClosed {
        require(teamTokensLockAddress == address(0) && totalSupply < HARD_CAP);
 
         
        uint256 teamTokens = 1350000000 * 10**uint256(decimals);

         
        TokenTimelock teamTokensLock = new TokenTimelock(this, mobilinkTeamAddress, uint64(block.timestamp) + 60 * 60 * 24 * 90);
        teamTokensLockAddress = address(teamTokensLock);
        totalSupply = totalSupply.add(teamTokens);
        balances[teamTokensLockAddress] = teamTokens;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(stageOneClosed) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(stageOneClosed || msg.sender == owner || (msg.sender == saleTokensVault && _to == owner)) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}