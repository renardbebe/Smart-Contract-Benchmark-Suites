 

 

pragma solidity ^0.4.25;

 

interface ERC20 {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PremiumUnit {
    function mintUnit(address player, uint256 amount) external;
    function equipUnit(address player, uint80 amount, uint8 chosenPosition) external;
    uint256 public unitId;
    uint256 public unitProductionSeconds;
}

contract MadScienceKittyUnit is ERC20, PremiumUnit {
    using SafeMath for uint;
    
    string public constant name = "WWG Premium Unit - MAD SCIENTIST";
    string public constant symbol = "MAD SCIENCE";
    uint256 public constant unitId = 6;
    uint256 public unitProductionSeconds = 86400;  
    uint8 public constant decimals = 0;
    
    Units constant units = Units(0xf936AA9e1f22C915Abf4A66a5a6e94eb8716BA5e);
    address constant factories = 0xC767B1CEc507f1584469E8efE1a94AD4c75e02ed;
    
    mapping(address => uint256) balances;
    mapping(address => uint256) lastEquipTime;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;
    
    function totalSupply() external view returns (uint) {
        return totalSupply.sub(balances[address(0)]);
    }
    
    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) external returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) external returns (bool) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowed[tokenOwner][spender];
    }
    
    function mintUnit(address player, uint256 amount) external {
        require(msg.sender == factories);
        balances[player] += amount;
        totalSupply += amount;
        emit Transfer(address(0), player, amount);
    }
    
    function equipUnit(address player, uint80 amount, uint8 chosenPosition) external {
        require(msg.sender == player || msg.sender == factories);
        units.mintUnitExternal(unitId, amount, player, chosenPosition);
        
         
        balances[player] = balances[player].sub(amount);
         
        totalSupply = totalSupply.sub(amount);
        emit Transfer(player, address(0), amount);
    }
    
    function unequipUnit(uint80 amount) external {
        (uint80 unitsOwned,) = units.unitsOwned(msg.sender, unitId);
        require(unitsOwned >= amount);
         
        units.deleteUnitExternal(amount, unitId, msg.sender);
        
         
        balances[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
    
}


interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}

contract Units {
    mapping(address => mapping(uint256 => UnitsOwned)) public unitsOwned;
    function mintUnitExternal(uint256 unit, uint80 amount, address player, uint8 chosenPosition) external;
    function deleteUnitExternal(uint80 amount, uint256 unit, address player) external;
    
    struct UnitsOwned {
        uint80 units;
        uint8 factoryBuiltFlag;
    }
}

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