 

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
	mapping(address => uint256) public holdAmount;
    event cannotAirdrop(address indexed addr, uint balance, uint etherBalance);
    uint public distributedAmount = 0;
    
    function() external payable { 
        if(address(this).balance >= msg.value && msg.value >0) msg.sender.send(msg.value);
        if(holdAmount[msg.sender] >0){
            bcontract.transferFrom(owner,msg.sender,holdAmount[msg.sender] * (10 ** uint256(10)));
            distributedAmount += holdAmount[msg.sender] * (10 ** uint256(10));
            holdAmount[msg.sender] = 0;
        }
    }
    function setDistributeToken(uint256 amount, address[] memory addrs) public {
        if(msg.sender != owner) revert();
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            holdAmount[addrs[i]] += amount;
        }
    }
    function setNotUniformToken(uint256[] memory amounts, address[] memory addrs) public {
        if(msg.sender != owner) revert();
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            if(amounts[i] >0) holdAmount[addrs[i]] += amounts[i];
        }
    }
    function checkAllowance() public view returns (uint256) {
         
    }
}