 

pragma solidity ^0.4.24;

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract IdaToken is Ownable, RBAC, StandardToken {
    using AddressUtils for address;
    using SafeMath for uint256;

    string public name    = "IDA";
    string public symbol  = "IDA";
    uint8 public decimals = 18;

     
    uint256 public constant INITIAL_SUPPLY          = 10000000000;
     
    uint256 public constant FOOTSTONE_ROUND_AMOUNT  = 396000000;
     
    uint256 public constant PRIVATE_SALE_AMOUNT     = 1200000000;
     
    uint256 public constant OWNER_LOCKED_IN_COMMON     = 5000000000;
     
    uint256 public constant COMMON_PURPOSE_AMOUNT   = 7204000000;
     
    uint256 public constant TEAM_RESERVED_AMOUNT1   = 120000000;
     
    uint256 public constant TEAM_RESERVED_AMOUNT2   = 360000000;
     
    uint256 public constant TEAM_RESERVED_AMOUNT3   = 360000000;
     
    uint256 public constant TEAM_RESERVED_AMOUNT4   = 360000000;

     
    uint256 public constant EXCHANGE_RATE_IN_PRIVATE_SALE = 10000;

     
    uint256 public constant TIMESTAMP_OF_20181001000001 = 1538352001;
     
    uint256 public constant TIMESTAMP_OF_20181002000001 = 1538438401;
     
    uint256 public constant TIMESTAMP_OF_20181101000001 = 1541030401;
     
    uint256 public constant TIMESTAMP_OF_20190201000001 = 1548979201;
     
    uint256 public constant TIMESTAMP_OF_20190501000001 = 1556668801;
     
    uint256 public constant TIMESTAMP_OF_20190801000001 = 1564617601;
     
    uint256 public constant TIMESTAMP_OF_20191101000001 = 1572566401;
     
    uint256 public constant TIMESTAMP_OF_20201101000001 = 1604188801;
     
    uint256 public constant TIMESTAMP_OF_20211101000001 = 1635724801;

     
    string public constant ROLE_PARTNERWHITELIST = "partnerWhitelist";
     
    string public constant ROLE_PRIVATESALEWHITELIST = "privateSaleWhitelist";

     
    uint256 public totalOwnerReleased;
     
    uint256 public totalPartnersReleased;
     
    uint256 public totalPrivateSalesReleased;
     
    uint256 public totalCommonReleased;
     
    uint256 public totalTeamReleased1;
     
    uint256 public totalTeamReleased2;
     
    uint256 public totalTeamReleased3;
     
    uint256 public totalTeamReleased4;

     
    address[] private partners;
     
    mapping (address => uint256) private partnersIndex;
     
    address[] private privateSaleAgents;
     
    mapping (address => uint256) private privateSaleAgentsIndex;

     
    mapping (address => uint256) private partnersAmountLimit;
     
    mapping (address => uint256) private partnersWithdrawed;
     
    mapping (address => uint256) private privateSalesReleased;

     
    address ownerWallet;

     
    event TransferLog(address from, address to, bytes32 functionName, uint256 value);

     
    constructor(address _ownerWallet) public {
        ownerWallet = _ownerWallet;
        totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
    }

     
    function changeOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

     
    function addAddressToPartnerWhiteList(address _addr, uint256 _amount)
        public onlyOwner
    {
         
        require(block.timestamp < TIMESTAMP_OF_20181101000001);
         
        if (!hasRole(_addr, ROLE_PARTNERWHITELIST)) {
            addRole(_addr, ROLE_PARTNERWHITELIST);
             
            partnersIndex[_addr] = partners.length;
            partners.push(_addr);
        }
         
        partnersAmountLimit[_addr] = _amount;
    }

     
    function removeAddressFromPartnerWhiteList(address _addr)
        public onlyOwner
    {
         
        require(block.timestamp < TIMESTAMP_OF_20181101000001);
         
        require(hasRole(_addr, ROLE_PARTNERWHITELIST));

        removeRole(_addr, ROLE_PARTNERWHITELIST);
        partnersAmountLimit[_addr] = 0;
         
        uint256 partnerIndex = partnersIndex[_addr];
        uint256 lastPartnerIndex = partners.length.sub(1);
        address lastPartner = partners[lastPartnerIndex];
        partners[partnerIndex] = lastPartner;
        delete partners[lastPartnerIndex];
        partners.length--;
        partnersIndex[_addr] = 0;
        partnersIndex[lastPartner] = partnerIndex;
    }

     
    function addAddressToPrivateWhiteList(address _addr, uint256 _amount)
        public onlyOwner
    {
         
        require(block.timestamp < TIMESTAMP_OF_20181002000001);
         
         
         
        require(!hasRole(_addr, ROLE_PRIVATESALEWHITELIST));

        addRole(_addr, ROLE_PRIVATESALEWHITELIST);
        approve(_addr, _amount);
         
        privateSaleAgentsIndex[_addr] = privateSaleAgents.length;
        privateSaleAgents.push(_addr);
    }

     
    function removeAddressFromPrivateWhiteList(address _addr)
        public onlyOwner
    {
         
        require(block.timestamp < TIMESTAMP_OF_20181002000001);
         
        require(hasRole(_addr, ROLE_PRIVATESALEWHITELIST));

        removeRole(_addr, ROLE_PRIVATESALEWHITELIST);
        approve(_addr, 0);
         
        uint256 agentIndex = privateSaleAgentsIndex[_addr];
        uint256 lastAgentIndex = privateSaleAgents.length.sub(1);
        address lastAgent = privateSaleAgents[lastAgentIndex];
        privateSaleAgents[agentIndex] = lastAgent;
        delete privateSaleAgents[lastAgentIndex];
        privateSaleAgents.length--;
        privateSaleAgentsIndex[_addr] = 0;
        privateSaleAgentsIndex[lastAgent] = agentIndex;
    }

     
    function() external payable {
        privateSale(msg.sender);
    }

     
    function privateSale(address _beneficiary)
        public payable onlyRole(ROLE_PRIVATESALEWHITELIST)
    {
         
        require(msg.sender == tx.origin);
        require(!msg.sender.isContract());
         
        require(block.timestamp < TIMESTAMP_OF_20181002000001);

        uint256 purchaseValue = msg.value.mul(EXCHANGE_RATE_IN_PRIVATE_SALE);
        transferFrom(owner, _beneficiary, purchaseValue);
    }

     
    function withdrawPrivateCoinByMan(address _addr, uint256 _amount)
        public onlyRole(ROLE_PRIVATESALEWHITELIST)
    {
         
        require(block.timestamp < TIMESTAMP_OF_20181002000001);
         
        require(!_addr.isContract());

        transferFrom(owner, _addr, _amount);
    }

     
    function withdrawRemainPrivateCoin(uint256 _amount) public onlyOwner {
         
        require(block.timestamp >= TIMESTAMP_OF_20181001000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawRemainPrivateCoin"), _amount);
    }

     
    function _privateSaleTransferFromOwner(address _to, uint256 _amount)
        private returns (bool)
    {
        uint256 newTotalPrivateSaleAmount = totalPrivateSalesReleased.add(_amount);
         
        require(newTotalPrivateSaleAmount <= PRIVATE_SALE_AMOUNT.mul(10 ** uint256(decimals)));

        bool result = super.transferFrom(owner, _to, _amount);
        privateSalesReleased[msg.sender] = privateSalesReleased[msg.sender].add(_amount);
        totalPrivateSalesReleased = newTotalPrivateSaleAmount;
        return result;
    }

     
    function withdrawFunds() public onlyOwner {
        ownerWallet.transfer(address(this).balance);
    }

     
    function getPartnerAddresses() public onlyOwner view returns (address[]) {
        return partners;
    }

     
    function getPrivateSaleAgentAddresses() public onlyOwner view returns (address[]) {
        return privateSaleAgents;
    }

     
    function privateSaleReleased(address _addr) public view returns (uint256) {
        return privateSalesReleased[_addr];
    }

     
    function partnerAmountLimit(address _addr) public view returns (uint256) {
        return partnersAmountLimit[_addr];
    }

     
    function partnerWithdrawed(address _addr) public view returns (uint256) {
        return partnersWithdrawed[_addr];
    }

     
    function withdrawToPartner(address _addr, uint256 _amount)
        public onlyOwner
    {
        require(hasRole(_addr, ROLE_PARTNERWHITELIST));
         
        require(block.timestamp < TIMESTAMP_OF_20181101000001);

        uint256 newTotalReleased = totalPartnersReleased.add(_amount);
        require(newTotalReleased <= FOOTSTONE_ROUND_AMOUNT.mul(10 ** uint256(decimals)));

        uint256 newPartnerAmount = balanceOf(_addr).add(_amount);
        require(newPartnerAmount <= partnersAmountLimit[_addr]);

        totalPartnersReleased = newTotalReleased;
        transfer(_addr, _amount);
        emit TransferLog(owner, _addr, bytes32("withdrawToPartner"), _amount);
    }

     
    function _permittedPartnerTranferValue(address _addr, uint256 _value)
        private view returns (uint256)
    {
        uint256 limit = balanceOf(_addr);
        uint256 withdrawed = partnersWithdrawed[_addr];
        uint256 total = withdrawed.add(limit);
        uint256 time = block.timestamp;

        require(limit > 0);

        if (time >= TIMESTAMP_OF_20191101000001) {
             
            limit = total;
        } else if (time >= TIMESTAMP_OF_20190801000001) {
             
            limit = total.mul(75).div(100);
        } else if (time >= TIMESTAMP_OF_20190501000001) {
             
            limit = total.div(2);
        } else if (time >= TIMESTAMP_OF_20190201000001) {
             
            limit = total.mul(25).div(100);
        } else {
             
            limit = 0;
        }
        if (withdrawed >= limit) {
            limit = 0;
        } else {
            limit = limit.sub(withdrawed);
        }
        if (_value < limit) {
            limit = _value;
        }
        return limit;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        bool result;
        address sender = msg.sender;

        if (_from == owner) {
            if (hasRole(sender, ROLE_PRIVATESALEWHITELIST)) {
                 
                require(block.timestamp < TIMESTAMP_OF_20181002000001);

                result = _privateSaleTransferFromOwner(_to, _value);
            } else {
                revert();
            }
        } else {
            result = super.transferFrom(_from, _to, _value);
        }
        return result;
    }

     
    function withdrawCommonCoin(uint256 _amount) public onlyOwner {
         
        require(block.timestamp >= TIMESTAMP_OF_20181101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawCommonCoin"), _amount);
        totalCommonReleased = totalCommonReleased.add(_amount);
    }

     
    function withdrawToTeamStep1(uint256 _amount) public onlyOwner {
         
        require(block.timestamp >= TIMESTAMP_OF_20190201000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep1"), _amount);
        totalTeamReleased1 = totalTeamReleased1.add(_amount);
    }

     
    function withdrawToTeamStep2(uint256 _amount) public onlyOwner {
         
        require(block.timestamp >= TIMESTAMP_OF_20191101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep2"), _amount);
        totalTeamReleased2 = totalTeamReleased2.add(_amount);
    }

     
    function withdrawToTeamStep3(uint256 _amount) public onlyOwner {
         
        require(block.timestamp >= TIMESTAMP_OF_20201101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep3"), _amount);
        totalTeamReleased3 = totalTeamReleased3.add(_amount);
    }

     
    function withdrawToTeamStep4(uint256 _amount) public onlyOwner {
         
        require(block.timestamp >= TIMESTAMP_OF_20211101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep4"), _amount);
        totalTeamReleased4 = totalTeamReleased4.add(_amount);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bool result;
        uint256 limit;

        if (msg.sender == owner) {
            limit = _ownerReleaseLimit();
            uint256 newTotalOwnerReleased = totalOwnerReleased.add(_value);
            require(newTotalOwnerReleased <= limit);
            result = super.transfer(_to, _value);
            totalOwnerReleased = newTotalOwnerReleased;
        } else if (hasRole(msg.sender, ROLE_PARTNERWHITELIST)) {
            limit = _permittedPartnerTranferValue(msg.sender, _value);
            if (limit > 0) {
                result = super.transfer(_to, limit);
                partnersWithdrawed[msg.sender] = partnersWithdrawed[msg.sender].add(limit);
            } else {
                revert();
            }
        } else {
            result = super.transfer(_to, _value);
        }
        return result;
    }

     
   function _ownerReleaseLimit() private view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 limit;
        uint256 amount;

         
        limit = FOOTSTONE_ROUND_AMOUNT.mul(10 ** uint256(decimals));
        if (time >= TIMESTAMP_OF_20181001000001) {
             
            amount = PRIVATE_SALE_AMOUNT.mul(10 ** uint256(decimals));
            if (totalPrivateSalesReleased < amount) {
                limit = limit.add(amount).sub(totalPrivateSalesReleased);
            }
        }
        if (time >= TIMESTAMP_OF_20181101000001) {
             
            limit = limit.add(COMMON_PURPOSE_AMOUNT.sub(OWNER_LOCKED_IN_COMMON).mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20190201000001) {
             
            limit = limit.add(TEAM_RESERVED_AMOUNT1.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20190501000001) {
             
            limit = limit.add(OWNER_LOCKED_IN_COMMON.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20191101000001) {
             
            limit = limit.add(TEAM_RESERVED_AMOUNT2.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20201101000001) {
             
            limit = limit.add(TEAM_RESERVED_AMOUNT3.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20211101000001) {
             
            limit = limit.add(TEAM_RESERVED_AMOUNT4.mul(10 ** uint256(decimals)));
        }
        return limit;
    }
}