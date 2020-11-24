 

pragma solidity ^0.4.13;

contract ERC20 {

     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);



     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}


contract AirDrop{
    address owner;
    mapping(address => uint256) tokenBalance;
    
    function AirDrop(){
        owner=msg.sender;
    }
    
    function transfer(address _token,address _to,uint256 _amount) public returns(bool){
        require(msg.sender==owner);
        ERC20 token=ERC20(_token);
        return token.transfer(_to,_amount);
    }
    
    function doAirdrop(address _token,address[] _to,uint256 _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transferFrom(msg.sender,_to[i],_amount);
        }
    }
    
    function doAirdrop2(address _token,address[] _to,uint256 _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transfer(_to[i],_amount);
        }
    }
    
    function doCustomAirdrop(address _token,address[] _to,uint256[] _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transferFrom(msg.sender,_to[i],_amount[i]);
        }
    }
    
    function doCustomAirdrop2(address _token,address[] _to,uint256[] _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transfer(_to[i],_amount[i]);
        }
    }
}