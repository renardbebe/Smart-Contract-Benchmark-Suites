 

pragma solidity ^0.4.18;


 
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

     
    function transferOwnership(address newOwner) onlyOwner public {
         
        require(newOwner != address(0));
         
        OwnershipTransferred(owner, newOwner);
         
        owner = newOwner;
    }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract QwasderToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

     
    uint256 public totalSupply_ = 0;
    mapping(address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) internal allowed;

     
    bool public mintingFinished = false;

     
    uint256 public grantsUnlock = 1523318400;  
    uint256 public reservedSupply = 20000000000000000000000000;
     

     
    uint256 public cap = 180000000000000000000000000;
     

     
    string public name     = "Qwasder";
    string public symbol   = "QWS";
    uint8  public decimals = 18;

     
    mapping (address => bool) partners;
    mapping (address => bool) blacklisted;
    mapping (address => bool) freezed;
    uint256 public publicRelease   = 1525046400;  
    uint256 public partnersRelease = 1539129600;  
    uint256 public hardcap = 200000000000000000000000000;
     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

     
    event Grant(address indexed to, uint256 amount);

     
    event Burn(address indexed burner, uint256 value);

     
    event UpdatedPublicReleaseDate(uint256 date);
    event UpdatedPartnersReleaseDate(uint256 date);
    event UpdatedGrantsLockDate(uint256 date);
    event Blacklisted(address indexed account);
    event Freezed(address indexed investor);
    event PartnerAdded(address indexed investor);
    event PartnerRemoved(address indexed investor);
    event Unfreezed(address indexed investor);

     
    function QwasderToken() public {
        assert(reservedSupply < cap && reservedSupply.add(cap) == hardcap);
        assert(publicRelease <= partnersRelease);
        assert(grantsUnlock < partnersRelease);
    }

     

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     

    modifier canGrant() {
        require(now >= grantsUnlock && reservedSupply > 0);
        _;
    }

     

     
    function totalSupply() public view returns (uint256 total) {
        return totalSupply_;
    }

     
    function balanceOf(address investor) public view returns (uint256 balance) {
        return balances[investor];
    }

     
    function transfer(address to, uint256 amount) public returns (bool success) {
        require(!freezed[msg.sender] && !blacklisted[msg.sender]);
        require(to != address(0) && !freezed[to] && !blacklisted[to]);
        require((!partners[msg.sender] && now >= publicRelease) || now >= partnersRelease);
        require(0 < amount && amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        Transfer(msg.sender, to, amount);
        return true;
    }

     

     
    function allowance(address holder, address spender) public view returns (uint256 remaining) {
        return allowed[holder][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(!blacklisted[msg.sender]);
        require(to != address(0) && !freezed[to] && !blacklisted[to]);
        require(from != address(0) && !freezed[from] && !blacklisted[from]);
        require((!partners[from] && now >= publicRelease) || now >= partnersRelease);
        require(0 < amount && amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        Transfer(from, to, amount);
        return true;
    }

     

     
    function decreaseApproval(address spender, uint256 amount) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (amount > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(amount);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     
    function increaseApproval(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(amount);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     

     
    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool success) {
        require(!freezed[to] && !blacklisted[to] && !partners[to]);
        uint256 total = totalSupply_.add(amount);
        require(total <= cap);
        totalSupply_ = total;
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool success) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

     

     
    function grant(address to, uint256 amount) onlyOwner canGrant public returns (bool success) {
        require(!freezed[to] && !blacklisted[to] && partners[to]);
        require(amount <= reservedSupply);
        totalSupply_ = totalSupply_.add(amount);
        reservedSupply = reservedSupply.sub(amount);
        balances[to] = balances[to].add(amount);
        Grant(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }

     

     
    function burn(uint256 amount) public returns (bool success) {
        require(!freezed[msg.sender]);
        require((!partners[msg.sender] && now >= publicRelease) || now >= partnersRelease);
        require(amount > 0 && amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        Burn(msg.sender, amount);
        Transfer(msg.sender, address(0), amount);
        return true;
    }

     

     
    function addPartner(address investor) onlyOwner public returns (bool) {
        require(investor != address(0));
        require(!partners[investor] && !blacklisted[investor] && balances[investor] == 0);
        partners[investor] = true;
        PartnerAdded(investor);
        return partners[investor];
    }

     
    function removePartner(address investor) onlyOwner public returns (bool) {
        require(partners[investor] && balances[investor] == 0);
        partners[investor] = false;
        PartnerRemoved(investor);
        return !partners[investor];
    }

     
    function blacklist(address account) onlyOwner public returns (bool) {
        require(account != address(0));
        require(!blacklisted[account]);
        blacklisted[account] = true;
        totalSupply_ = totalSupply_.sub(balances[account]);
        uint256 amount = balances[account];
        balances[account] = 0;
        Blacklisted(account);
        Burn(account, amount);
        return blacklisted[account];
    }

     
    function freeze(address investor) onlyOwner public returns (bool) {
        require(investor != address(0));
        require(!freezed[investor]);
        freezed[investor] = true;
        Freezed(investor);
        return freezed[investor];
    }

     
    function unfreeze(address investor) onlyOwner public returns (bool) {
        require(freezed[investor]);
        freezed[investor] = false;
        Unfreezed(investor);
        return !freezed[investor];
    }

     
    function setPublicRelease(uint256 date) onlyOwner public returns (bool success) {
        require(now < publicRelease && date > publicRelease);
        require(date.sub(publicRelease) <= 604800);
        publicRelease = date;
        assert(publicRelease <= partnersRelease);
        UpdatedPublicReleaseDate(date);
        return true;
    }

     
    function setPartnersRelease(uint256 date) onlyOwner public returns (bool success) {
        require(now < partnersRelease && date > partnersRelease);
        require(date.sub(partnersRelease) <= 604800);
        partnersRelease = date;
        assert(grantsUnlock < partnersRelease);
        UpdatedPartnersReleaseDate(date);
        return true;
    }

     
    function setGrantsUnlock(uint256 date, bool extendLocking) onlyOwner public returns (bool success) {
        require(now < grantsUnlock && date > grantsUnlock);
        if (extendLocking) {
          uint256 delay = date.sub(grantsUnlock);
          require(delay <= 604800);
          grantsUnlock = date;
          publicRelease = publicRelease.add(delay);
          partnersRelease = partnersRelease.add(delay);
          assert(publicRelease <= partnersRelease);
          assert(grantsUnlock < partnersRelease);
          UpdatedPublicReleaseDate(publicRelease);
          UpdatedPartnersReleaseDate(partnersRelease);
        }
        else {
           
          grantsUnlock = date;
          assert(grantsUnlock < partnersRelease);
        }
        UpdatedGrantsLockDate(date);
        return true;
    }

     
    function extendLockPeriods(uint delay, bool extendGrantLock) onlyOwner public returns (bool success) {
        require(now < publicRelease && 0 < delay && delay <= 168);
        delay = delay * 3600;
        publicRelease = publicRelease.add(delay);
        partnersRelease = partnersRelease.add(delay);
        assert(publicRelease <= partnersRelease);
        UpdatedPublicReleaseDate(publicRelease);
        UpdatedPartnersReleaseDate(partnersRelease);
        if (extendGrantLock) {
            grantsUnlock = grantsUnlock.add(delay);
            assert(grantsUnlock < partnersRelease);
            UpdatedGrantsLockDate(grantsUnlock);
        }
        return true;
    }

}