 

pragma solidity ^0.4.21;

contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

contract ERC20Token is ERC20Interface {

    using SafeMath for uint256;

     
    uint256 internal totalTokenIssued;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256) {
        return totalTokenIssued;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }


     
    function transfer(address _to, uint256 _amount) public returns (bool) {

        require(_to != address(0x0));

         
        require(isContract(_to) == false);

         
        require(balances[msg.sender] >= _amount);

        
         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to]        = balances[_to].add(_amount);

         
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    

     
    function approve(address _spender, uint256 _amount) public returns (bool) {
        
        require(_spender != address(0x0));

         
        allowed[msg.sender][_spender] = _amount;

         
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        
        require(_to != address(0x0));
        
         
        require(isContract(_to) == false);

         
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);

         
        balances[_from]            = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]              = balances[_to].add(_amount);

         
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / b);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return (a - b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract WhiteListManager is Ownable {

     
    mapping (address => bool) public list;

    function unset(address addr) public onlyOwner {

        list[addr] = false;
    }

    function unsetMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            unset(addrList[i]);
        }
    }

    function set(address addr) public onlyOwner {

        list[addr] = true;
    }

    function setMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            set(addrList[i]);
        }
    }

    function isWhitelisted(address addr) public view returns (bool) {

        return list[addr];
    }
}

contract ShareToken is ERC20Token, WhiteListManager {

    using SafeMath for uint256;

    string public constant name = "ShareToken";
    string public constant symbol = "SHR";
    uint8  public constant decimals = 2;

    address public icoContract;

     
    uint256 constant E2 = 10**2;

    mapping(address => bool) public rewardTokenLocked;
    bool public mainSaleTokenLocked = true;

    uint256 public constant TOKEN_SUPPLY_MAINSALE_LIMIT = 1000000000 * E2;  
    uint256 public constant TOKEN_SUPPLY_AIRDROP_LIMIT  = 6666666667;  
    uint256 public constant TOKEN_SUPPLY_BOUNTY_LIMIT   = 33333333333;  

    uint256 public airDropTokenIssuedTotal;
    uint256 public bountyTokenIssuedTotal;

    uint256 public constant TOKEN_SUPPLY_SEED_LIMIT      = 500000000 * E2;  
    uint256 public constant TOKEN_SUPPLY_PRESALE_LIMIT   = 2500000000 * E2;  
    uint256 public constant TOKEN_SUPPLY_SEED_PRESALE_LIMIT = TOKEN_SUPPLY_SEED_LIMIT + TOKEN_SUPPLY_PRESALE_LIMIT;

    uint256 public seedAndPresaleTokenIssuedTotal;

    uint8 private constant PRESALE_EVENT    = 0;
    uint8 private constant MAINSALE_EVENT   = 1;
    uint8 private constant BOUNTY_EVENT     = 2;
    uint8 private constant AIRDROP_EVENT    = 3;

    function ShareToken() public {

        totalTokenIssued = 0;
        airDropTokenIssuedTotal = 0;
        bountyTokenIssuedTotal = 0;
        seedAndPresaleTokenIssuedTotal = 0;
        mainSaleTokenLocked = true;
    }

    function unlockMainSaleToken() public onlyOwner {

        mainSaleTokenLocked = false;
    }

    function lockMainSaleToken() public onlyOwner {

        mainSaleTokenLocked = true;
    }

    function unlockRewardToken(address addr) public onlyOwner {

        rewardTokenLocked[addr] = false;
    }

    function unlockRewardTokenMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            unlockRewardToken(addrList[i]);
        }
    }

    function lockRewardToken(address addr) public onlyOwner {

        rewardTokenLocked[addr] = true;
    }

    function lockRewardTokenMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {

            lockRewardToken(addrList[i]);
        }
    }

     
    function isLocked(address addr) public view returns (bool) {

         
        if (mainSaleTokenLocked) {
            return true;
        } else {

             
            if (isWhitelisted(addr)) {
                return false;
            } else {
                 
                 
                return rewardTokenLocked[addr];
            }
        }
    }

    function totalSupply() public view returns (uint256) {

        return totalTokenIssued.add(seedAndPresaleTokenIssuedTotal).add(airDropTokenIssuedTotal).add(bountyTokenIssuedTotal);
    }

    function totalMainSaleTokenIssued() public view returns (uint256) {

        return totalTokenIssued;
    }

    function totalMainSaleTokenLimit() public view returns (uint256) {

        return TOKEN_SUPPLY_MAINSALE_LIMIT;
    }

    function totalPreSaleTokenIssued() public view returns (uint256) {

        return seedAndPresaleTokenIssuedTotal;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {

        require(isLocked(msg.sender) == false);    
        require(isLocked(_to) == false);
        
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        
        require(isLocked(_from) == false);
        require(isLocked(_to) == false);
        
        return super.transferFrom(_from, _to, _amount);
    }

    function setIcoContract(address _icoContract) public onlyOwner {
        
         
        require(icoContract == address(0));
        require(_icoContract != address(0));

        icoContract = _icoContract;
    }

    function sell(address buyer, uint256 tokens) public returns (bool success) {
      
        require (icoContract != address(0));
         
        require (msg.sender == icoContract);
        require (tokens > 0);
        require (buyer != address(0));

         
        require (isWhitelisted(buyer));

        require (totalTokenIssued.add(tokens) <= TOKEN_SUPPLY_MAINSALE_LIMIT);

         
        balances[buyer] = balances[buyer].add(tokens);

         
        totalTokenIssued = totalTokenIssued.add(tokens);

        emit Transfer(address(MAINSALE_EVENT), buyer, tokens);

        return true;
    }

    function rewardAirdrop(address _to, uint256 _amount) public onlyOwner {

         
        require(_amount <= TOKEN_SUPPLY_AIRDROP_LIMIT);

        require(airDropTokenIssuedTotal < TOKEN_SUPPLY_AIRDROP_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_AIRDROP_LIMIT.sub(airDropTokenIssuedTotal);
        if (_amount > remainingTokens) {
            _amount = remainingTokens;
        }

         
        balances[_to] = balances[_to].add(_amount);

         
        airDropTokenIssuedTotal = airDropTokenIssuedTotal.add(_amount);

         
        rewardTokenLocked[_to] = true;

        emit Transfer(address(AIRDROP_EVENT), _to, _amount);
    }

    function rewardBounty(address _to, uint256 _amount) public onlyOwner {

         
        require(_amount <= TOKEN_SUPPLY_BOUNTY_LIMIT);

        require(bountyTokenIssuedTotal < TOKEN_SUPPLY_BOUNTY_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_BOUNTY_LIMIT.sub(bountyTokenIssuedTotal);
        if (_amount > remainingTokens) {
            _amount = remainingTokens;
        }

         
        balances[_to] = balances[_to].add(_amount);

         
        bountyTokenIssuedTotal = bountyTokenIssuedTotal.add(_amount);

         
        rewardTokenLocked[_to] = true;

        emit Transfer(address(BOUNTY_EVENT), _to, _amount);
    }

    function rewardBountyMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            rewardBounty(addrList[i], amountList[i]);
        }
    }

    function rewardAirdropMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            rewardAirdrop(addrList[i], amountList[i]);
        }
    }

    function handlePresaleToken(address _to, uint256 _amount) public onlyOwner {

        require(_amount <= TOKEN_SUPPLY_SEED_PRESALE_LIMIT);

        require(seedAndPresaleTokenIssuedTotal < TOKEN_SUPPLY_SEED_PRESALE_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_SEED_PRESALE_LIMIT.sub(seedAndPresaleTokenIssuedTotal);
        require (_amount <= remainingTokens);

         
        balances[_to] = balances[_to].add(_amount);

         
        seedAndPresaleTokenIssuedTotal = seedAndPresaleTokenIssuedTotal.add(_amount);

        emit Transfer(address(PRESALE_EVENT), _to, _amount);

         
        set(_to);
    }

    function handlePresaleTokenMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            handlePresaleToken(addrList[i], amountList[i]);
        }
    }
}