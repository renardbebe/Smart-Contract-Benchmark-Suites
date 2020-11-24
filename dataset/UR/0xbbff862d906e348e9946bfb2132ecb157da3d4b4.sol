 

 
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

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}
  
 
contract SharderToken {
    using SafeMath for uint256;
    string public name = "Sharder";
    string public symbol = "SS";
    uint8 public decimals = 18;

     
     
     
     
     
     
     
     
     
     
     
     
     
    
     
    uint256 public totalSupply = 350000000000000000000000000;

     
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    mapping (address => uint256) public balanceOf;

     
    address public owner;

     
    address public admin;

     
    mapping (address => bool) internal accountLockup;

     
    mapping (address => uint256) public accountLockupTime;
    
     
    mapping (address => bool) public frozenAccounts;
    
     
    mapping (address => uint256) internal holderIndex;

     
    address[] internal holders;

     
    bool internal firstRoundTokenIssued = false;

     
    bool public paused = true;

     
    uint256 internal issueIndex = 0;

     
    event InvalidState(bytes msg);

     
    event Issue(uint256 issueIndex, address addr, uint256 ethAmount, uint256 tokenAmount);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event FrozenFunds(address target, bool frozen);

     
    event Pause();

     
    event Unpause();

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

     
    modifier isNotFrozen {
        require(frozenAccounts[msg.sender] != true && now > accountLockupTime[msg.sender]);
        _;
    }

     
    modifier isNotPaused() {
        require((msg.sender == owner && paused) || (msg.sender == admin && paused) || !paused);
        _;
    }

     
    modifier isPaused() {
        require(paused);
        _;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal isNotFrozen isNotPaused {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        addOrUpdateHolder(_from);
        addOrUpdateHolder(_to);
         
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _transferTokensWithDecimal) public {
        _transfer(msg.sender, _to, _transferTokensWithDecimal);
    }

     
    function transferFrom(address _from, address _to, uint256 _transferTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(_transferTokensWithDecimal <= allowance[_from][msg.sender]);
         
        allowance[_from][msg.sender] -= _transferTokensWithDecimal;
        _transfer(_from, _to, _transferTokensWithDecimal);
        return true;
    }

     
    function approve(address _spender, uint256 _approveTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _approveTokensWithDecimal;
        Approval(msg.sender, _spender, _approveTokensWithDecimal);
        return true;
    }

     
    function burn(uint256 _burnedTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(balanceOf[msg.sender] >= _burnedTokensWithDecimal);
         
        balanceOf[msg.sender] -= _burnedTokensWithDecimal;
         
        totalSupply -= _burnedTokensWithDecimal;
        Burn(msg.sender, _burnedTokensWithDecimal);
        return true;
    }

     
    function burnFrom(address _from, uint256 _burnedTokensWithDecimal) public isNotFrozen isNotPaused returns (bool success) {
        require(balanceOf[_from] >= _burnedTokensWithDecimal);
         
        require(_burnedTokensWithDecimal <= allowance[_from][msg.sender]);
         
        balanceOf[_from] -= _burnedTokensWithDecimal;
         
        allowance[_from][msg.sender] -= _burnedTokensWithDecimal;
         
        totalSupply -= _burnedTokensWithDecimal;
        Burn(_from, _burnedTokensWithDecimal);
        return true;
    }

     
    function addOrUpdateHolder(address _holderAddr) internal {
         
        if (holderIndex[_holderAddr] == 0) {
            holderIndex[_holderAddr] = holders.length++;
            holders[holderIndex[_holderAddr]] = _holderAddr;
        }
    }

     
    function SharderToken() public {
        owner = msg.sender;
        admin = msg.sender;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

     
    function setAdmin(address _address) public onlyOwner {
        admin = _address;
    }

     
    function issueFirstRoundToken() public onlyOwner {
        require(!firstRoundTokenIssued);

        balanceOf[owner] = balanceOf[owner].add(totalSupply);
        Issue(issueIndex++, owner, 0, totalSupply);
        addOrUpdateHolder(owner);
        firstRoundTokenIssued = true;
    }

     
    function issueReserveToken(uint256 _issueTokensWithDecimal) onlyOwner public {
        balanceOf[owner] = balanceOf[owner].add(_issueTokensWithDecimal);
        totalSupply = totalSupply.add(_issueTokensWithDecimal);
        Issue(issueIndex++, owner, 0, _issueTokensWithDecimal);
    }

     
    function changeFrozenStatus(address _address, bool _frozenStatus) public onlyAdmin {
        frozenAccounts[_address] = _frozenStatus;
    }

     
    function lockupAccount(address _address, uint256 _lockupSeconds) public onlyAdmin {
        require((accountLockup[_address] && now > accountLockupTime[_address]) || !accountLockup[_address]);
         
        accountLockupTime[_address] = now + _lockupSeconds;
        accountLockup[_address] = true;
    }

     
    function getHolderCount() public view returns (uint256 _holdersCount){
        return holders.length - 1;
    }

     
    function getHolders() public onlyAdmin view returns (address[] _holders){
        return holders;
    }

     
    function pause() onlyAdmin isNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyAdmin isPaused public {
        paused = false;
        Unpause();
    }

     
    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }

     
    function setName(string _name) public onlyOwner {
        name = _name;
    }

     
    function() public payable {
        revert();
    }

}