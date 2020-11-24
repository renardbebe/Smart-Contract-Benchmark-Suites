 

pragma solidity ^0.5.7;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library StringUtils {
    
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);            
        }
        return string(s);
    }
    
    function _char(byte b) internal pure returns (byte c) {
        if (uint8(b) < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
    
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    function append3(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
    
    function append4(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

library IterableMap {
    
    struct IMap {
        mapping(address => uint256) mapToData;
        mapping(address => uint256) mapToIndex;  
        address[] indexes;
    }
    
    function insert(IMap storage self, address _address, uint256 _value) internal returns (bool replaced) {
      
        require(_address != address(0));
        
        if(self.mapToIndex[_address] == 0){
            
             
            self.indexes.push(_address);
            self.mapToIndex[_address] = self.indexes.length;
            self.mapToData[_address] = _value;
            return false;
        }
        
         
        self.mapToData[_address] = _value;
        return true;
    }
    
    function remove(IMap storage self, address _address) internal returns (bool success) {
       
        require(_address != address(0));
        
         
        if(self.mapToIndex[_address] == 0){
            return false;   
        }
        
        uint256 deleteIndex = self.mapToIndex[_address];
        if(deleteIndex <= 0 || deleteIndex > self.indexes.length){
            return false;
        }
       
          
        if (deleteIndex < self.indexes.length) {
             
            self.indexes[deleteIndex-1] = self.indexes[self.indexes.length-1];
            self.mapToIndex[self.indexes[deleteIndex-1]] = deleteIndex;
        }
        self.indexes.length -= 1;
        delete self.mapToData[_address];
        delete self.mapToIndex[_address];
       
        return true;
    }
  
    function contains(IMap storage self, address _address) internal view returns (bool exists) {
        return self.mapToIndex[_address] > 0;
    }
      
    function size(IMap storage self) internal view returns (uint256) {
        return self.indexes.length;
    }
  
    function get(IMap storage self, address _address) internal view returns (uint256) {
        return self.mapToData[_address];
    }

     
    function getKey(IMap storage self, uint256 _index) internal view returns (address) {
        
        if(_index < self.indexes.length){
            return self.indexes[_index];
        }
        return address(0);
    }
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


contract ERC20Votable is ERC20{
    
     
    using IterableMap for IterableMap.IMap;
    using SafeMath for uint256;
    
     
    event MintToken(uint256 sessionID, address indexed beneficiary, uint256 amount);
    event MintFinished(uint256 sessionID);
    event BurnToken(uint256 sessionID, address indexed beneficiary, uint256 amount);
    event AddAuthority(uint256 sessionID, address indexed authority);
    event RemoveAuthority(uint256 sessionID, address indexed authority);
    event ChangeRequiredApproval(uint256 sessionID, uint256 from, uint256 to);
    
    event VoteAccept(uint256 sessionID, address indexed authority);
    event VoteReject(uint256 sessionID, address indexed authority);
    
     
    uint256 constant NUMBER_OF_BLOCK_FOR_SESSION_EXPIRE = 5760;

     
    IterableMap.IMap authorities;
    
    bool public isMintingFinished;
    
    struct Topic {
        uint8 BURN;
        uint8 MINT;
        uint8 MINT_FINISHED;
        uint8 ADD_AUTHORITY;
        uint8 REMOVE_AUTHORITY;
        uint8 CHANGE_REQUIRED_APPROVAL;
    }
    
    struct Session {
        uint256 id;
        uint8 topic;
        uint256 blockNo;
        uint256 referNumber;
        address referAddress;
        uint256 countAccept;
        uint256 countReject;
        
        uint256 requireAccept;
    }
    
    ERC20Votable.Topic topic;
    ERC20Votable.Session session;
    
    constructor() public {
        
        topic.BURN = 1;
        topic.MINT = 2;
        topic.MINT_FINISHED = 3;
        topic.ADD_AUTHORITY = 4;
        topic.REMOVE_AUTHORITY = 5;
        topic.CHANGE_REQUIRED_APPROVAL = 6;
        
        session.id = 1;
        session.requireAccept = 1;
    
        authorities.insert(msg.sender, session.id);
    }
    
     
    modifier onlyAuthority() {
        require(authorities.contains(msg.sender));
        _;
    }
    
    modifier onlySessionAvailable() {
        require(_isSessionAvailable());
        _;
    }
    
     modifier onlyHasSession() {
        require(!_isSessionAvailable());
        _;
    }
    
    function isAuthority(address _address) public view returns (bool){
        return authorities.contains(_address);
    }

     
    function getSessionName() public view returns (string memory){
        
        bool isSession = !_isSessionAvailable();
        
        if(isSession){
            return (_getSessionName());
        }
        
        return "None";
    }
    
    function getSessionExpireAtBlockNo() public view returns (uint256){
        
        bool isSession = !_isSessionAvailable();
        
        if(isSession){
            return (session.blockNo.add(NUMBER_OF_BLOCK_FOR_SESSION_EXPIRE));
        }
        
        return 0;
    }
    
    function getSessionVoteAccept() public view returns (uint256){
      
        bool isSession = !_isSessionAvailable();
        
        if(isSession){
            return session.countAccept;
        }
        
        return 0;
    }
    
    function getSessionVoteReject() public view returns (uint256){
      
        bool isSession = !_isSessionAvailable();
        
        if(isSession){
            return session.countReject;
        }
        
        return 0;
    }
    
    function getSessionRequiredAcceptVote() public view returns (uint256){
      
        return session.requireAccept;
    }
    
    function getTotalAuthorities() public view returns (uint256){
      
        return authorities.size();
    }
    

    
     
     
    function createSessionMintToken(address _beneficiary, uint256 _amount) public onlyAuthority onlySessionAvailable {
        
        require(!isMintingFinished);
        require(_amount > 0);
        require(_beneficiary != address(0));
       
        _createSession(topic.MINT);
        session.referNumber = _amount;
        session.referAddress = _beneficiary;
    }
    
    function createSessionMintFinished() public onlyAuthority onlySessionAvailable {
        
        require(!isMintingFinished);
        _createSession(topic.MINT_FINISHED);
        session.referNumber = 0;
        session.referAddress = address(0);
    }
    
    function createSessionBurnAuthorityToken(address _authority, uint256 _amount) public onlyAuthority onlySessionAvailable {
        
        require(_amount > 0);
        require(_authority != address(0));
        require(isAuthority(_authority));
       
        _createSession(topic.BURN);
        session.referNumber = _amount;
        session.referAddress = _authority;
    }
    
    function createSessionAddAuthority(address _authority) public onlyAuthority onlySessionAvailable {
        
        require(!authorities.contains(_authority));
        
        _createSession(topic.ADD_AUTHORITY);
        session.referNumber = 0;
        session.referAddress = _authority;
    }
    
    function createSessionRemoveAuthority(address _authority) public onlyAuthority onlySessionAvailable {
        
        require(authorities.contains(_authority));
        
         
        require(authorities.size() > 1);
      
        _createSession(topic.REMOVE_AUTHORITY);
        session.referNumber = 0;
        session.referAddress = _authority;
    }
    
    function createSessionChangeRequiredApproval(uint256 _to) public onlyAuthority onlySessionAvailable {
        
        require(_to != session.requireAccept);
        require(_to <= authorities.size());

        _createSession(topic.CHANGE_REQUIRED_APPROVAL);
        session.referNumber = _to;
        session.referAddress = address(0);
    }
    
     
    function voteAccept() public onlyAuthority onlyHasSession {
        
         
        require(authorities.get(msg.sender) != session.id);
        
        authorities.insert(msg.sender, session.id);
        session.countAccept = session.countAccept.add(1);
        
        emit VoteAccept(session.id, session.referAddress);
        
         
        if(session.countAccept >= session.requireAccept){
            
            if(session.topic == topic.BURN){
                
                _burnToken();
                
            }else if(session.topic == topic.MINT){
                
                _mintToken();
                
            }else if(session.topic == topic.MINT_FINISHED){
                
                _finishMinting();
                
            }else if(session.topic == topic.ADD_AUTHORITY){
                
                _addAuthority();    
            
            }else if(session.topic == topic.REMOVE_AUTHORITY){
                
                _removeAuthority();  
                
            }else if(session.topic == topic.CHANGE_REQUIRED_APPROVAL){
                
                _changeRequiredApproval();  
                
            }
        }
    }
    
    function voteReject() public onlyAuthority onlyHasSession {
        
         
        require(authorities.get(msg.sender) != session.id);
        
        authorities.insert(msg.sender, session.id);
        session.countReject = session.countReject.add(1);
        
        emit VoteReject(session.id, session.referAddress);
    }
    
     
    function _createSession(uint8 _topic) internal {
        
        session.topic = _topic;
        session.countAccept = 0;
        session.countReject = 0;
        session.id = session.id.add(1);
        session.blockNo = block.number;
    }
    
    function _getSessionName() internal view returns (string memory){
        
        string memory topicName = "";
        
        if(session.topic == topic.BURN){
          
           topicName = StringUtils.append3("Burn ", StringUtils.uint2str(session.referNumber) , " token(s)");
           
        }else if(session.topic == topic.MINT){
          
           topicName = StringUtils.append4("Mint ", StringUtils.uint2str(session.referNumber) , " token(s) to address 0x", StringUtils.toAsciiString(session.referAddress));
         
        }else if(session.topic == topic.MINT_FINISHED){
          
           topicName = "Finish minting";
         
        }else if(session.topic == topic.ADD_AUTHORITY){
          
           topicName = StringUtils.append3("Add 0x", StringUtils.toAsciiString(session.referAddress), " to authorities");
           
        }else if(session.topic == topic.REMOVE_AUTHORITY){
            
            topicName = StringUtils.append3("Remove 0x", StringUtils.toAsciiString(session.referAddress), " from authorities");
            
        }else if(session.topic == topic.CHANGE_REQUIRED_APPROVAL){
            
            topicName = StringUtils.append4("Change approval from ", StringUtils.uint2str(session.requireAccept), " to ", StringUtils.uint2str(session.referNumber));
            
        }
        
        return topicName;
    }
    
    function _isSessionAvailable() internal view returns (bool){
        
         
        if(session.countAccept >= session.requireAccept) return true;
        
          
        if(session.countReject > authorities.size().sub(session.requireAccept)) return true;
        
         
        if(block.number.sub(session.blockNo) > NUMBER_OF_BLOCK_FOR_SESSION_EXPIRE) return true;
        
        return false;
    }   
    
    function _addAuthority() internal {
        
        authorities.insert(session.referAddress, session.id);
        emit AddAuthority(session.id, session.referAddress);
    }
    
    function _removeAuthority() internal {
        
        authorities.remove(session.referAddress);
        if(authorities.size() < session.requireAccept){
            emit ChangeRequiredApproval(session.id, session.requireAccept, authorities.size());
            session.requireAccept = authorities.size();
        }
        emit RemoveAuthority(session.id, session.referAddress);
    }
    
    function _changeRequiredApproval() internal {
        
        emit ChangeRequiredApproval(session.id, session.requireAccept, session.referNumber);
        session.requireAccept = session.referNumber;
        session.countAccept = session.requireAccept;
    }
    
    function _mintToken() internal {
        
        require(!isMintingFinished);
        _mint(session.referAddress, session.referNumber);
        emit MintToken(session.id, session.referAddress, session.referNumber);
    }
    
    function _finishMinting() internal {
        
        require(!isMintingFinished);
        isMintingFinished = true;
        emit MintFinished(session.id);
    }
    
    function _burnToken() internal {
        
        _burn(session.referAddress, session.referNumber);
        emit BurnToken(session.id, session.referAddress, session.referNumber);
    }
}

contract WorldClassSmartFarmToken is ERC20Detailed, ERC20Votable {
    constructor (string memory name, string memory symbol, uint8 decimals)
        public
        ERC20Detailed(name, symbol, decimals)
    {
        
    }
}