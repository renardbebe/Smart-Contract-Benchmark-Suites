 

pragma solidity ^0.4.24;

 

 
 
 

contract SafeBlocksProxy {

    event AllowTransactionResult(address sourceAddress, bool approved, address token, uint amount, address destination, uint blockNumber);
    event AllowAccessResult(address sourceAddress, bool approved, address destination, bytes4 functionSig, uint blockNumber);
    event ConfigurationChanged(address sender, address newConfiguration, string message);

    address private owner;
    address private superOwner;
    bool private isBypassMode;
    bytes32 private hashedPwd;
    SafeBlocksFirewall private safeBlocksFirewall;

    constructor(address _superOwner, bytes32 _hashedPwd) public {
        owner = msg.sender;
        superOwner = _superOwner;
        hashedPwd = _hashedPwd;
        isBypassMode = false;
    }

     

    modifier onlyContractOwner {
        require(owner == msg.sender, "You are not allowed to run this function, required role: Contract-Owner");
        _;
    }

    modifier onlySuperOwner {
        require(superOwner == msg.sender, "You are not allowed to run this function, required role: Super-Owner");
        _;
    }

     
    modifier onlySuperOwnerWithPwd(string pwd, bytes32 newHashedPwd) {
        require(superOwner == msg.sender && hashedPwd == keccak256(abi.encodePacked(pwd)), "You are not allowed to run this function, required role: Super-Owner with Password");
        hashedPwd = newHashedPwd;
        _;
    }

     

    function setSuperOwner(address newSuperOwner, string pwd, bytes32 newHashedPwd)
    onlySuperOwnerWithPwd(pwd, newHashedPwd)
    public {
        superOwner = newSuperOwner;
        emit ConfigurationChanged(msg.sender, newSuperOwner, "a new Super-Owner has been assigned");
    }

    function setOwner(address newOwner, string pwd, bytes32 newHashedPwd)
    onlySuperOwnerWithPwd(pwd, newHashedPwd)
    public {
        owner = newOwner;
        emit ConfigurationChanged(msg.sender, newOwner, "a new Owner has been assigned");
    }

    function setBypassForAll(bool _bypass)
    onlySuperOwner
    public {
        isBypassMode = _bypass;
        emit ConfigurationChanged(msg.sender, msg.sender, "a new Bypass-Mode has been assigned");
    }

    function getBypassStatus()
    public
    view
    onlyContractOwner
    returns (bool){
        return isBypassMode;
    }

    function setSBFWContractAddress(address _sbfwAddress)
    onlyContractOwner
    public {
        safeBlocksFirewall = SafeBlocksFirewall(_sbfwAddress);
        emit ConfigurationChanged(msg.sender, _sbfwAddress, "a new address has been assigned to SafeBlocksFirewall");
    }

     

     
    function allowTransaction(uint _amount, address _destination, address _token)
    public
    returns (bool) {
        address senderAddress = msg.sender;

        if (isBypassMode) {
            emit AllowTransactionResult(senderAddress, true, _token, _amount, _destination, block.number);
            return true;
        }
        bool result = safeBlocksFirewall.allowTransaction(senderAddress, _amount, _destination, _token);
        emit AllowTransactionResult(senderAddress, result, _token, _amount, _destination, block.number);
        return result;
    }

     
    function allowAccess(address _destination, bytes4 _functionSig)
    public
    returns (bool) {
        address senderAddress = msg.sender;

        if (isBypassMode) {
            emit AllowAccessResult(senderAddress, true, _destination, _functionSig, block.number);
            return true;
        }
        bool result = safeBlocksFirewall.allowAccess(senderAddress, _destination, _functionSig);
        emit AllowAccessResult(senderAddress, result, _destination, _functionSig, block.number);
        return result;
    }
}

interface SafeBlocksFirewall {

     
    function allowTransaction(
        address contractAddress,
        uint amount,
        address destination,
        address token)
    external
    returns (bool);

     
    function allowAccess(
        address contractAddress,
        address destination,
        bytes4 functionSig)
    external
    returns (bool);
}

 