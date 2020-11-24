 

 
 
 
 

pragma solidity ^0.4.8;

 
 
contract Fundraiser {


     
    uint public constant dust = 1 finney;  


     
     
     
    address public admin;
    address public treasury;

     
    uint public beginBlock;
    uint public endBlock;

     
    uint public weiPerAtom; 

     
    bool public isHalted = false;

     
    mapping (address => uint) public record;

     
    uint public totalWei = 0;
     
    uint public totalAtom = 0;
     
    uint public numDonations = 0;

     
     
     
     
    function Fundraiser(address _admin, address _treasury, uint _beginBlock, uint _endBlock, uint _weiPerAtom) {
        admin = _admin;
        treasury = _treasury;
        beginBlock = _beginBlock;
        endBlock = _endBlock;
	weiPerAtom = _weiPerAtom;
    }

     
    modifier only_admin { if (msg.sender != admin) throw; _; }
     
    modifier only_before_period { if (block.number >= beginBlock) throw; _; }
     
    modifier only_during_period { if (block.number < beginBlock || block.number >= endBlock || isHalted) throw; _; }
     
    modifier only_during_halted_period { if (block.number < beginBlock || block.number >= endBlock || !isHalted) throw; _; }
     
    modifier only_after_period { if (block.number < endBlock) throw; _; }
     
    modifier is_not_dust { if (msg.value < dust) throw; _; }

     
    event Received(address indexed recipient, address returnAddr, uint amount, uint currentRate);
     
    event Halted();
     
    event Unhalted();

     
    function isActive() constant returns (bool active) {
	return (block.number >= beginBlock && block.number < endBlock && !isHalted);
    }

     
    function donate(address _donor, address _returnAddress, bytes4 checksum) payable only_during_period is_not_dust {
	 
	if ( !( bytes4(sha3( bytes32(_donor)^bytes32(_returnAddress) )) == checksum )) throw;

	 
        if (!treasury.send(msg.value)) throw;

	 
	var atoms = msg.value / weiPerAtom;

	 
        record[_donor] += atoms;

	 
        totalWei += msg.value;
	totalAtom += atoms;
	numDonations += 1;

        Received(_donor, _returnAddress, msg.value, weiPerAtom);
    }

     
    function adjustRate(uint newRate) only_admin {
	weiPerAtom = newRate;
    }

     
    function halt() only_admin only_during_period {
        isHalted = true;
        Halted();
    }

     
    function unhalt() only_admin only_during_halted_period {
        isHalted = false;
        Unhalted();
    }

     
    function kill() only_admin only_after_period {
        suicide(treasury);
    }
}