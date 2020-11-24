 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

pragma solidity ^0.5.0;

 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.11;




contract ColendiScore is Ownable{
    using ECDSA for bytes32;

     

    event LogScoreUpdate(bytes32 queryId);

     

    struct ScoreQuery {
        address requestor;
        address user;
        uint32 score;
        uint256 updateTime;
        bytes32 IPFSHash;
    }
     struct OwnScoreQuery {
        address user;
        uint32 score;
        uint256 updateTime;
    }

     

     
    address public scoreController;

     
    mapping(address => uint256) currentNonce;

     
    mapping(bytes32 => ScoreQuery) scoreQueries;

     
    mapping(bytes32 => OwnScoreQuery) ownScoreQueries;

     
    uint256 public queryCost = 10**19;

     
    ERC20 colendiToken;

     

    modifier onlyScoreController(){
        require(msg.sender == scoreController, "Only colendi score controller can execute this transaction");
        _;
    }


     
    modifier hasValidProof(bytes memory sig, address userAddr, uint256 nonce){
        require(nonce == currentNonce[userAddr], "Not a valid nonce");
         
        address recoveredUserAddr = recoverSigner(userAddr,nonce,sig);
         
        require(recoveredUserAddr == userAddr, "Unmatched signature");
        _;
    }

     

     
     
     
     
     
    function recoverSigner(address userAddr, uint256 nonce, bytes memory signature) public view returns(address recoveredAddress){
        bytes32 _hashOfMsg = calculateHashWithPrefix(userAddr,nonce);
        recoveredAddress = _hashOfMsg.recover(signature);
    }

     
     
     
     
    function calculateHashWithPrefix(address userAddr, uint256 nonce) public view returns(bytes32 prefixedHash) {
        prefixedHash = keccak256(abi.encodePacked(address(this),userAddr,nonce)).toEthSignedMessageHash();
    }

     
     
     

    function getScoreQuery(bytes32 queryID) external view returns(address requestor, address user, uint32 score, uint256 updateTime, bytes32 IPFSHash){
        ScoreQuery memory scoreQuery = scoreQueries[queryID];
        requestor = scoreQuery.requestor;
        user = scoreQuery.user;
        score = scoreQuery.score;
        updateTime = scoreQuery.updateTime;
        IPFSHash = scoreQuery.IPFSHash;
    }

    function getOwnScoreQuery(bytes32 queryID) external view returns(address user, uint32 score, uint256 updateTime){
        OwnScoreQuery memory ownScoreQuery = ownScoreQueries[queryID];
        user = ownScoreQuery.user;
        score = ownScoreQuery.score;
        updateTime = ownScoreQuery.updateTime;
    }

     
     
     
     
     
    function updateScore(bytes memory signature, address requestor, address userAddr, uint256 nonce, uint32 _score, bytes32 IPFSHash)
    public hasValidProof(signature, userAddr, nonce) onlyScoreController
    {
        require(colendiToken.transferFrom(requestor, address(this), queryCost), "Failed Token Transfer");
        bytes32 queryID = keccak256(abi.encodePacked(userAddr, nonce));
        scoreQueries[queryID].requestor = requestor;
        scoreQueries[queryID].user = userAddr;
        scoreQueries[queryID].score = _score;
        scoreQueries[queryID].updateTime = now;
        scoreQueries[queryID].IPFSHash = IPFSHash;
        currentNonce[userAddr] = nonce + 1;
        emit LogScoreUpdate(queryID);

    }

     
     
     
     
    function updateOwnScore(bytes memory signature, address userAddr, uint256 nonce, uint32 _score)
    public hasValidProof(signature, userAddr, nonce) onlyScoreController
    {
        require(colendiToken.transferFrom(userAddr, address(this), queryCost), "Failed Token Transfer");
        bytes32 queryID = keccak256(abi.encodePacked(userAddr, nonce));
        ownScoreQueries[queryID].updateTime = now;
        ownScoreQueries[queryID].user = userAddr;
        ownScoreQueries[queryID].score = _score;
        currentNonce[userAddr] = nonce + 1;
        emit LogScoreUpdate(queryID);
    }

     
     
     
    function getNonceOfUser(address userAddr) external view returns(uint256 nonce){
        nonce = currentNonce[userAddr];
    }

    function updateQueryCost(uint256 _queryCost) public onlyScoreController returns(bool) {
        queryCost = _queryCost;
    }
     
    function () external payable{
    }

     
    function getCODBack() external onlyScoreController {
        require(colendiToken.transfer(msg.sender,colendiToken.balanceOf(address(this))), "Unsuccessful  COD Transfer");
    }

     
    function getEthBack() external onlyScoreController {
        msg.sender.transfer(address(this).balance);
    }

    function transferColendiController(address _colendiController) public onlyOwner{
        scoreController = _colendiController;
    }

     
     
    constructor(address CODToken) public {
        colendiToken = ERC20(CODToken);
        scoreController = msg.sender;
    }

}