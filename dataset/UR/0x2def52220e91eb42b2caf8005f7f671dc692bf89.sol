 

pragma solidity ^0.5.3;

contract TokenERC20 {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}
contract multiSend{
    address public baseAddr = 0x500Df47E1dF0ef06039218dCF0960253D89D6658;
     
    address payable public owner = 0xA5BC03ddc951966B0Df385653fA5b7CAdF1fc3DA;
	TokenERC20 bcontract = TokenERC20(baseAddr);
	multiSend oldAddress = multiSend(0x03d0a7f0519946E723aa76372Bb34A9540F628ae);
	mapping(address => uint256) public holdAmount;
	mapping(address => uint256) public setAmount;
	mapping(address => bool) public isOldAmountSent;
	address[] public bountyHunterAddresses;
    uint public distributedAmount = 0;
    
    function() external payable { 
        if(address(this).balance >= msg.value && msg.value >0) 
            msg.sender.transfer(msg.value);
        if(holdAmount[msg.sender] >0){
            uint256 sendingAmount = holdAmount[msg.sender] * (10 ** uint256(10));
            if(!isOldAmountSent[msg.sender] && oldAddress.holdAmount(msg.sender) >0){ 
                sendingAmount += oldAddress.holdAmount(msg.sender) * (10 ** uint256(10));
                isOldAmountSent[msg.sender] = true;
            }
            bcontract.transferFrom(owner,msg.sender,sendingAmount);
            distributedAmount += sendingAmount;
            holdAmount[msg.sender] = 0;
        }
    }
    function addNewPhase() public {
        if(msg.sender != owner) revert();
        if(bountyHunterAddresses.length <= 0) revert();
        for(uint i=0;i<bountyHunterAddresses.length;i++){
            address nextAddress = bountyHunterAddresses[i];
            if(setAmount[nextAddress] >0) holdAmount[nextAddress] += setAmount[nextAddress];
        }
    }
    function setDistributeToken(uint256 amount, address[] memory addrs) public {
        if(msg.sender != owner) revert();
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            if(setAmount[addrs[i]] <=0) bountyHunterAddresses.push(addrs[i]);
            holdAmount[addrs[i]] += amount;
            setAmount[addrs[i]] += amount;
        }
    }
    function setNotUniformToken(uint256[] memory amounts, address[] memory addrs) public {
        if(msg.sender != owner) revert();
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            if(amounts[i] >0){
                if(setAmount[addrs[i]] <=0) bountyHunterAddresses.push(addrs[i]);
                holdAmount[addrs[i]] += amounts[i];
                setAmount[addrs[i]] += amounts[i];
            } 
        }
    }
    function checkAllowance() public view returns (uint256) {
        return bcontract.allowance(owner,address(this));
    }
}