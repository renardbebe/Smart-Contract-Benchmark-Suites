 

pragma solidity >=0.4.21 <0.6.0;

contract Loyalty {

    struct Enterprises {
        uint id;
        string name;
        uint balance;
    }

    mapping(uint => Enterprises) public enterpises;

    uint public enterprisesCount;   
    
     
    event votedEvent (
        uint indexed _enterpriseId
    );

    constructor () public {
    }

    function addEnterprise (string memory _name,uint _balance) public {
        require(_balance >= 0);
        enterprisesCount ++;
        enterpises[enterprisesCount] = Enterprises(enterprisesCount, _name,_balance);
    }
    
    function updateBalance(uint _id,uint _balance) public{
        require(_id > 0 && _id <= enterprisesCount);
        require(_balance > 0);
        enterpises[_id].balance += _balance;
        emit votedEvent(_id);
    }
    
    function redemptionBalance(uint _id,uint _balance) public{
        require(_id > 0 && _id <= enterprisesCount);
        require(_balance > 0 && enterpises[_id].balance >= _balance);
        enterpises[_id].balance -= _balance;
        emit votedEvent(_id);
    }
}