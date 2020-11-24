 

pragma solidity ^0.4.11;

 

contract Cubic {

    uint public creationTime = now;
    address public owner = msg.sender;
    uint256 public totalEthHandled = 0; 
    uint public rate = 0; 
    Cube[] public Cubes;

     

    event Freeze(address indexed from, address indexed cubeAddress, uint amount, uint unlockedAfter, string api);
    event Deliver(address indexed cube, address indexed destination, uint amount);

     

    function() payable { }

    function getCubeCount() external constant returns(uint) {
        return Cubes.length;
    }

    function freeze(uint blocks) external payable {
        secure(blocks, 'cubic');
    }

    function freezeAPI(uint blocks, string api) external payable {
        secure(blocks, api);
    }

    function forgetCube(Cube iceCube) external {

        uint id = iceCube.id();
        require(msg.sender == address(Cubes[id]));

        if (id != Cubes.length - 1) {
            Cubes[id] = Cubes[Cubes.length - 1];
            Cubes[id].setId(id);
        }
        Cubes.length--;        

        Deliver(address(iceCube), iceCube.destination(), iceCube.balance);
    }

     

    function withdraw() external {
        require(msg.sender == owner);        
        owner.transfer(this.balance);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner);        
        owner = newOwner;
    }

     

	function secure(uint blocks, string api) private {

        require(msg.value > 0);
        uint amountToFreeze = msg.value; 
        totalEthHandled = add(totalEthHandled, amountToFreeze);
          
         
        if (rate != 200 ) {

            if (totalEthHandled > 5000 ether) {
                setRate(200);   
            } else if (totalEthHandled > 1000 ether) { 
                setRate(500);   
            } else if (totalEthHandled > 100 ether) { 
                setRate(1000);  
            }
        }

        if (rate > 0) {
            uint fee = div(amountToFreeze, rate);
            amountToFreeze = sub(amountToFreeze, fee);
        }

        Cube newCube = (new Cube).value(amountToFreeze)(msg.sender, add(block.number, blocks), this);
        newCube.setId(Cubes.push(newCube) - 1);
        Freeze(msg.sender, address(newCube), amountToFreeze, add(block.number, blocks), api);
	}

    function setRate(uint _newRate) private {
        rate = _newRate; 
    }

    function add(uint a, uint b) private returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function div(uint a, uint b) private returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) private returns (uint) {
        assert(b <= a);
        return a - b;
    }

}

contract Cube {

    address public destination;
    Cubic public cubicContract;    
    uint public unlockedAfter;
    uint public id;
    
	function Cube(address _destination, uint _unlockedAfter, Cubic _cubicContract) payable {
		destination = _destination;
		unlockedAfter = _unlockedAfter;
        cubicContract = _cubicContract;       
	}

    function() payable {
        require(msg.value == 0);
    }

    function setId(uint _id) external {
        require(msg.sender == address(cubicContract));
        id = _id; 
    }

    function deliver() external {
        assert(block.number > unlockedAfter); 
        cubicContract.forgetCube(this);
		selfdestruct(destination);		
	}
}