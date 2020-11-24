 

pragma solidity ^0.4.9;

contract OrangeGov_Main {
    address public currentContract;
    
	mapping(address=>mapping(string=>bool)) permissions;
	mapping(address=>mapping(string=>bool)) userStatuses;
	mapping(string=>address) contractIDs;
	mapping(string=>bool) contractIDExists;
	address[] contractArray;  
	function OrangeGov_Main () {
	    permissions[msg.sender]["all"]=true;
	}
	function getHasPermission(address user, string permissionName, string userStatusAllowed) returns (bool hasPermission){  
	    return permissions[msg.sender][permissionName]||permissions[msg.sender]["all"]||userStatuses[msg.sender][userStatusAllowed];
	}
	function getContractByID(string ID) returns (address addr,bool exists){  
	    return (contractIDs[ID],contractIDExists[ID]);
	}
	
    modifier permissionRequired(string permissionName,string userStatusAllowed) {
        _;  
        if (getHasPermission(msg.sender,permissionName,userStatusAllowed)){
            throw;
        }
    }
    
    function removeFromContractIDArray(address contractToRemove) {
        for (uint x=0;x<contractArray.length-1;x++) {
            if (contractArray[x]==contractToRemove) {
                contractArray[x]=contractArray[contractArray.length-1];
	            contractArray.length--;
	            return;
            }
        }
    }
    
	function addContract(string ID,bytes code) permissionRequired("addContract",""){
	    address addr;
        assembly {
            addr := create(0,add(code,0x20), mload(code))
            jumpi(invalidJumpLabel,iszero(extcodesize(addr)))
        }
        address oldAddr = contractIDs[ID];
	    contractIDs[ID]=addr;
	    contractIDExists[ID]=true;
	    oldAddr.call.gas(msg.gas)(bytes4(sha3("changeCurrentContract(address)")),addr);  
	    addr.call.gas(msg.gas)(bytes4(sha3("tellPreviousContract(address)")),oldAddr);  
	    removeFromContractIDArray(addr);
	    contractArray.length++;
	    contractArray[contractArray.length-1]=addr;
	}
	function removeContract(string ID) permissionRequired("removeContract",""){
	    contractIDExists[ID]=false;
	    contractIDs[ID].call.gas(msg.gas)(bytes4(sha3("changeCurrentContract(address)")),currentContract);  
	    removeFromContractIDArray(contractIDs[ID]);
	}
	function update(bytes code) permissionRequired("update",""){
	    address addr;
        assembly {
            addr := create(0,add(code,0x20), mload(code))
            jumpi(invalidJumpLabel,iszero(extcodesize(addr)))
        }
        addr.call.gas(msg.gas)(bytes4(sha3("tellPreviousContract(address)")),currentContract);
        currentContract = addr;
        for (uint x=0;x<contractArray.length-1;x++) {
            contractArray[x].call.gas(msg.gas)(bytes4(sha3("changeMain(address)")),currentContract);
        }
	}
	function tellPreviousContract(address prev) {  
	    
	}
	function spendEther(address addr, uint256 weiAmt) permissionRequired("spendEther",""){
	    if (!addr.send(weiAmt)) throw;
	}
	function givePermission(address addr, string permission) permissionRequired("givePermission",""){
	    if (getHasPermission(msg.sender,permission,"")){
	        permissions[addr][permission]=true;
	    }
	}
	function removePermission(address addr, string permission) permissionRequired("removePermission",""){
	    permissions[addr][permission]=false;
	}
}