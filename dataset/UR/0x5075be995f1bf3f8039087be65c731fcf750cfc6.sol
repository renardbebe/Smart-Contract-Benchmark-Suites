 

pragma solidity ^0.5.3;

 

 
contract ERC20Interface {
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who)public view returns (uint);
}

 
contract Forwarder {
    
    address payable public parentAddress;
 
    event ForwarderDeposited(address from, uint value, bytes data);
    event TokensFlushed(address forwarderAddress, uint value, address tokenContractAddress);

     
    modifier onlyParent {
        require(msg.sender == parentAddress);
        _;
    }
    
     
    constructor() public{
        parentAddress = msg.sender;
    }

     
    function() external payable {
        parentAddress.transfer(msg.value);
        emit ForwarderDeposited(msg.sender, msg.value, msg.data);
    }

     
    function flushTokens(address tokenContractAddress) public onlyParent {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint forwarderBalance = instance.balanceOf(address(this));
        require(forwarderBalance > 0);
        require(instance.transfer(parentAddress, forwarderBalance));
        emit TokensFlushed(address(this), forwarderBalance, tokenContractAddress);
    }
  
     
    function flushToken(address _from, uint _value) external{
        require(ERC20Interface(_from).transfer(parentAddress, _value), "instance error");
    }

     
    function flush() public {
        parentAddress.transfer(address(this).balance);
    }
}

 
contract MultiSignWallet {
    
    address[] public signers;
    bool public safeMode; 
    uint forwarderCount;
    uint lastsequenceId;
    
    event Deposited(address from, uint value, bytes data);
    event SafeModeActivated(address msgSender);
    event SafeModeInActivated(address msgSender);
    event ForwarderCreated(address forwarderAddress);
    event Transacted(address msgSender, address otherSigner, bytes32 operation, address toAddress, uint value, bytes data);
    event TokensTransfer(address tokenContractAddress, uint value);
    
     
    modifier onlySigner {
        require(isSigner(msg.sender));
        _;
    }

     
    constructor(address[] memory allowedSigners) public {
        require(allowedSigners.length == 3);
        signers = allowedSigners;
    }

     
    function() external payable {
        if(msg.value > 0){
            emit Deposited(msg.sender, msg.value, msg.data);
        }
    }
    
     
    function isSigner(address signer) public view returns (bool) {
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                return true;
            }
        }
        return false;
    }

     
    function activateSafeMode() public onlySigner {
        require(!safeMode);
        safeMode = true;
        emit SafeModeActivated(msg.sender);
    }
    
      
    function turnOffSafeMode() public onlySigner {
        require(safeMode);
        safeMode = false;
        emit SafeModeInActivated(msg.sender);
    }
    
     
    function createForwarder() public returns (address) {
        Forwarder f = new Forwarder();
        forwarderCount += 1;
        emit ForwarderCreated(address(f));
        return(address(f));
    }
    
     
    function getForwarder() public view returns(uint){
        return forwarderCount;
    }
    
     
    function flushForwarderTokens(address payable forwarderAddress, address tokenContractAddress) public onlySigner {
        Forwarder forwarder = Forwarder(forwarderAddress);
        forwarder.flushTokens(tokenContractAddress);
    }
    
     
    function getNextSequenceId() public view returns (uint) {
        return lastsequenceId+1;
    }
    
     
    function getHash(address toAddress, uint value, bytes memory data, uint expireTime, uint sequenceId)public pure returns (bytes32){
        return keccak256(abi.encodePacked("ETHER", toAddress, value, data, expireTime, sequenceId));
    }

     
    function sendMultiSig(address payable toAddress, uint value, bytes memory data, uint expireTime, uint sequenceId, bytes memory signature) public payable onlySigner {
        bytes32 operationHash = keccak256(abi.encodePacked("ETHER", toAddress, value, data, expireTime, sequenceId));
        address otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
        toAddress.transfer(value);
        emit Transacted(msg.sender, otherSigner, operationHash, toAddress, value, data);
    }
    
     
    function getTokenHash( address toAddress, uint value, address tokenContractAddress, uint expireTime, uint sequenceId) public pure returns (bytes32){
        return keccak256(abi.encodePacked("ERC20", toAddress, value, tokenContractAddress, expireTime, sequenceId));
    }
  
     
    function sendMultiSigToken(address toAddress, uint value, address tokenContractAddress, uint expireTime, uint sequenceId, bytes memory signature) public onlySigner {
        bytes32 operationHash = keccak256(abi.encodePacked("ERC20", toAddress, value, tokenContractAddress, expireTime, sequenceId));
        verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        require(instance.balanceOf(address(this)) > 0);
        require(instance.transfer(toAddress, value));
        emit TokensTransfer(tokenContractAddress, value);
    }
    
     
    function recoverAddressFromSignature(bytes32 operationHash, bytes memory signature) private pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27; 
        }
        return ecrecover(operationHash, v, r, s);
    }

     
    function tryInsertSequenceId(uint sequenceId) private onlySigner {
        require(sequenceId > lastsequenceId && sequenceId <= (lastsequenceId+1000), "Enter Valid sequenceId");
        lastsequenceId=sequenceId;
    }

     
    function verifyMultiSig(address toAddress, bytes32 operationHash, bytes memory signature, uint expireTime, uint sequenceId) private returns (address) {

        address otherSigner = recoverAddressFromSignature(operationHash, signature);
        if (safeMode && !isSigner(toAddress)) {
            revert("safemode error");
        }
        require(isSigner(otherSigner) && expireTime > now);
        require(otherSigner != msg.sender);
        tryInsertSequenceId(sequenceId);
        return otherSigner;
    }
}