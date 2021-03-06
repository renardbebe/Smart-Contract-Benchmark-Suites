 

 
pragma solidity 0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "mul overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0");  
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function roundedDiv(uint a, uint b) internal pure returns (uint256) {
        require(b > 0, "div by 0");  
        uint256 z = a / b;
        if (a % b >= b / 2) {
            z++;   
        }
        return z;
    }
}

contract MultiSig {
    using SafeMath for uint256;

    uint public constant CHUNK_SIZE = 100;

    mapping(address => bool) public isSigner;
    address[] public allSigners;  
                                 
                                 
    uint public activeSignersCount;

    enum ScriptState {New, Approved, Done, Cancelled, Failed}

    struct Script {
        ScriptState state;
        uint signCount;
        mapping(address => bool) signedBy;
        address[] allSigners;
    }

    mapping(address => Script) public scripts;
    address[] public scriptAddresses;

    event SignerAdded(address signer);
    event SignerRemoved(address signer);

    event ScriptSigned(address scriptAddress, address signer);
    event ScriptApproved(address scriptAddress);
    event ScriptCancelled(address scriptAddress);

    event ScriptExecuted(address scriptAddress, bool result);

    constructor() public {
         
         
        isSigner[msg.sender] = true;
        allSigners.push(msg.sender);
        activeSignersCount = 1;
        emit SignerAdded(msg.sender);
    }

    function sign(address scriptAddress) public {
        require(isSigner[msg.sender], "sender must be signer");
        Script storage script = scripts[scriptAddress];
        require(script.state == ScriptState.Approved || script.state == ScriptState.New,
                "script state must be New or Approved");
        require(!script.signedBy[msg.sender], "script must not be signed by signer yet");

        if(script.allSigners.length == 0) {
             
            scriptAddresses.push(scriptAddress);
        }

        script.allSigners.push(msg.sender);
        script.signedBy[msg.sender] =  true;
        script.signCount = script.signCount.add(1);

        emit ScriptSigned(scriptAddress, msg.sender);

        if(checkQuorum(script.signCount)){
            script.state = ScriptState.Approved;
            emit ScriptApproved(scriptAddress);
        }
    }

    function execute(address scriptAddress) public returns (bool result) {
         
        require(isSigner[msg.sender], "sender must be signer");
        Script storage script = scripts[scriptAddress];
        require(script.state == ScriptState.Approved, "script state must be Approved");

         
        script.state = ScriptState.Failed;

         
        if(scriptAddress.delegatecall(bytes4(keccak256("execute(address)")), scriptAddress)) {
            script.state = ScriptState.Done;
            result = true;
        } else {
            result = false;
        }
        emit ScriptExecuted(scriptAddress, result);
    }

    function cancelScript(address scriptAddress) public {
        require(msg.sender == address(this), "only callable via MultiSig");
        Script storage script = scripts[scriptAddress];
        require(script.state == ScriptState.Approved || script.state == ScriptState.New,
                "script state must be New or Approved");

        script.state= ScriptState.Cancelled;

        emit ScriptCancelled(scriptAddress);
    }

     
    function addSigners(address[] signers) public {
        require(msg.sender == address(this), "only callable via MultiSig");
        for (uint i= 0; i < signers.length; i++) {
            if (!isSigner[signers[i]]) {
                require(signers[i] != address(0), "new signer must not be 0x0");
                activeSignersCount++;
                allSigners.push(signers[i]);
                isSigner[signers[i]] = true;
                emit SignerAdded(signers[i]);
            }
        }
    }

     
    function removeSigners(address[] signers) public {
        require(msg.sender == address(this), "only callable via MultiSig");
        for (uint i= 0; i < signers.length; i++) {
            if (isSigner[signers[i]]) {
                require(activeSignersCount > 1, "must not remove last signer");
                activeSignersCount--;
                isSigner[signers[i]] = false;
                emit SignerRemoved(signers[i]);
            }
        }
    }

     
    function checkQuorum(uint signersCount) internal view returns(bool isQuorum);

    function getAllSignersCount() view external returns (uint allSignersCount) {
        return allSigners.length;
    }

     
    function getAllSigners(uint offset) external view returns(uint[3][CHUNK_SIZE] signersResult) {
        for (uint8 i = 0; i < CHUNK_SIZE && i + offset < allSigners.length; i++) {
            address signerAddress = allSigners[i + offset];
            signersResult[i] = [ i + offset, uint(signerAddress), isSigner[signerAddress] ? 1 : 0 ];
        }
    }

    function getScriptsCount() view external returns (uint scriptsCount) {
        return scriptAddresses.length;
    }

     
     
    function getAllScripts(uint offset) external view returns(uint[4][CHUNK_SIZE] scriptsResult) {
        for (uint8 i = 0; i < CHUNK_SIZE && i + offset < scriptAddresses.length; i++) {
            address scriptAddress = scriptAddresses[i + offset];
            scriptsResult[i] = [ i + offset, uint(scriptAddress), uint(scripts[scriptAddress].state),
                            scripts[scriptAddress].signCount ];
        }
    }

}

contract PreTokenProxy is MultiSig {

    function checkQuorum(uint signersCount) internal view returns(bool isQuorum) {
        isQuorum = signersCount > activeSignersCount / 2 ;
    }
}