 

pragma solidity ^0.4.24;

 
 
 
 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract HODL is Pausable {

    modifier hashDoesNotExist(string _hash){
        if(hashExistsMap[_hash] == true) revert();
        _;
    }

    mapping (string => bool) hashExistsMap;
    mapping (string => uint256) hashToIndex;
    
    mapping (address => uint256[]) senderToIndexArray;
    
    mapping (address => mapping (address => bool)) userOptOut;
    
    struct Hash {
        string hash;
        address sender;
        uint256 timestamp;
    }
    
    Hash[] public hashes;

    event AddedBatch(address indexed from, string hash, uint256 timestamp);
    event UserOptOut(address user, address appAddress, uint256 timestamp);
    event UserOptIn(address user, address appAddress, uint256 timestamp);

    function storeBatch(string _hash) public whenNotPaused hashDoesNotExist(_hash) {

        Hash memory newHash = Hash({
            hash: _hash,
            sender: msg.sender,
            timestamp: now
        });
        
        uint256 newHashIndex = hashes.push(newHash) - 1;
        
        hashToIndex[_hash] = newHashIndex;
        senderToIndexArray[msg.sender].push(newHashIndex);
        
        hashExistsMap[_hash] = true;
        
        emit AddedBatch(msg.sender, _hash, now);
    }

    
    function opt(address appAddress) public whenNotPaused {
        
        bool userOptState = userOptOut[msg.sender][appAddress];
        
        if(userOptState == false){
            userOptOut[msg.sender][appAddress] = true;
            emit UserOptIn(msg.sender, appAddress, now);
        }
        else{
            userOptOut[msg.sender][appAddress] = false;
            emit UserOptOut(msg.sender, appAddress, now);
        }
    }

    function getUserOptOut(address userAddress, address appAddress) public view returns (bool){
        return userOptOut[userAddress][appAddress];
    }
    
    function getIndexByHash (string _hash) public view returns (uint256){
        return hashToIndex[_hash];
    }

	function getHashExists(string _hash) public view returns (bool){
        return hashExistsMap[_hash];
    }
    
    function getAllIndexesByAddress (address sender) public view returns (uint256[]){
        return senderToIndexArray[sender];
    }
}