 

pragma solidity ^0.4.14;

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSMath {
    
     

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

     


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


     

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

     

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

     

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract TokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function totalSupply() constant returns (uint256) {
        return _supply;
    }
    function balanceOf(address addr) constant returns (uint256) {
        return _balances[addr];
    }
    function allowance(address from, address to) constant returns (uint256) {
        return _approvals[from][to];
    }
    
    function transfer(address to, uint value) returns (bool) {
        assert(_balances[msg.sender] >= value);
        
        _balances[msg.sender] = sub(_balances[msg.sender], value);
        _balances[to] = add(_balances[to], value);
        
        Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) returns (bool) {
        assert(_balances[from] >= value);
        assert(_approvals[from][msg.sender] >= value);
        
        _approvals[from][msg.sender] = sub(_approvals[from][msg.sender], value);
        _balances[from] = sub(_balances[from], value);
        _balances[to] = add(_balances[to], value);
        
        Transfer(from, to, value);
        
        return true;
    }
    
    function approve(address to, uint256 value) returns (bool) {
        _approvals[msg.sender][to] = value;
        
        Approval(msg.sender, to, value);
        
        return true;
    }

}

contract Owned
{
    address public owner;
    
    function Owned()
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }
}

contract Migrable is TokenBase, Owned
{
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    address public migrationAgent;
    uint256 public totalMigrated;


    function migrate() external {
        migrate_participant(msg.sender);
    }
    
    function migrate_participant(address _participant) internal
    {
         
        if (migrationAgent == 0)  revert();
        if (_balances[_participant] == 0)  revert();
        
        uint256 _value = _balances[_participant];
        _balances[_participant] = 0;
        _supply = sub(_supply, _value);
        totalMigrated = add(totalMigrated, _value);
        MigrationAgent(migrationAgent).migrateFrom(_participant, _value);
        Migrate(_participant, migrationAgent, _value);
        
    }

    function setMigrationAgent(address _agent) onlyOwner external {
        if (migrationAgent != 0)  revert();
        migrationAgent = _agent;
    }
}

contract ProspectorsGoldToken is TokenBase, Owned, Migrable {
    string public constant name = "Prospectors Gold";
    string public constant symbol = "PGL";
    uint8 public constant decimals = 18;   

    address private game_address = 0xb1;  
    uint public constant game_allocation = 110000000 * WAD;  
    uint public constant dev_allocation = 45000000 * WAD;  
    uint public constant crowdfunding_allocation = 60000000 * WAD;  
    uint public constant bounty_allocation = 500000 * WAD;  
    uint public constant presale_allocation = 4500000 * WAD;  

    bool public locked = true;  

    address public bounty;  
    address public prospectors_dev_allocation;  
    ProspectorsCrowdsale public crowdsale;  

    function ProspectorsGoldToken() {
        _supply = 220000000 * WAD;
        _balances[this] = _supply;
        mint_for(game_address, game_allocation);
    }
    
     
    function transfer(address to, uint value) returns (bool)
    {
        if (locked == true && msg.sender != address(crowdsale)) revert();
        return super.transfer(to, value);
    }
    
     
    function transferFrom(address from, address to, uint value)  returns (bool)
    {
        if (locked == true) revert();
        return super.transferFrom(from, to, value);
    }
    
     
    function unlock() returns (bool)
    {
        if (locked == true && crowdsale.is_success() == true)
        {
            locked = false;
            return true;
        }
        else
        {
            return false;
        }
    }

     
    function init_crowdsale(address _crowdsale) onlyOwner
    {
        if (address(0) != address(crowdsale)) revert();
        crowdsale = ProspectorsCrowdsale(_crowdsale);
        mint_for(crowdsale, crowdfunding_allocation);
    }
    
     
    function init_bounty_program(address _bounty) onlyOwner
    {
        if (address(0) != address(bounty)) revert();
        bounty = _bounty;
        mint_for(bounty, bounty_allocation);
    }
    
     
    function init_dev_and_presale_allocation(address presale_token_address, address _prospectors_dev_allocation) onlyOwner
    {
        if (address(0) != prospectors_dev_allocation) revert();
        prospectors_dev_allocation = _prospectors_dev_allocation;
        mint_for(prospectors_dev_allocation, dev_allocation);
        mint_for(presale_token_address, presale_allocation);
    }
    
     
    function migrate_game_balance() onlyOwner
    {
        migrate_participant(game_address);
    }
    
     
    function mint_for(address addr, uint amount) private
    {
        if (_balances[this] >= amount)
        {
            _balances[this] = sub(_balances[this], amount);
            _balances[addr] = add(_balances[addr], amount);
            Transfer(this, addr, amount);
        }
    }
}

contract ProspectorsCrowdsale {
    function is_success() returns (bool);
}

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}