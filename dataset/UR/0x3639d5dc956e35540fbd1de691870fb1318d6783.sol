 

pragma solidity ^0.4.23;

 
library MerkleProof {
   
  function verifyProof(
    bytes32[] _proof,
    bytes32 _root,
    bytes32 _leaf
  )
    internal
    pure
    returns (bool)
  {
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      bytes32 proofElement = _proof[i];

      if (computedHash < proofElement) {
         
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
         
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

     
    return computedHash == _root;
  }
}



contract Controlled {

    mapping(address => bool) public controllers;

     
     
    modifier onlyController { 
        require(controllers[msg.sender]); 
        _; 
    }

    address public controller;

    constructor() internal { 
        controllers[msg.sender] = true; 
        controller = msg.sender;
    }

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }

    function changeControllerAccess(address _controller, bool _access) public onlyController {
        controllers[_controller] = _access;
    }

}



 
 

interface ERC20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

     
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract SNTGiveaway is Controlled {
    
    mapping(address => bool) public sentToAddress;
    mapping(bytes5 => bool) public codeUsed;
    
    ERC20Token public SNT;
    
    uint public ethAmount;
    uint public sntAmount;
    bytes32 public root;
    
    event AddressFunded(address dest, bytes5 code, uint ethAmount, uint sntAmount);
    
     
     
     
     
     
    constructor(address _sntAddress, uint _ethAmount, uint _sntAmount, bytes32 _root) public {
        SNT = ERC20Token(_sntAddress);
        ethAmount = _ethAmount;
        sntAmount = _sntAmount;
        root = _root;
    }

     
     
     
     
    function validRequest(bytes32[] _proof, bytes5 _code, address _dest) public view returns(bool) {
        return !sentToAddress[_dest] && !codeUsed[_code] && MerkleProof.verifyProof(_proof, root, keccak256(abi.encodePacked(_code)));
    }

     
     
     
     
    function processRequest(bytes32[] _proof, bytes5 _code, address _dest) public onlyController {
        require(!sentToAddress[_dest] && !codeUsed[_code], "Funds already sent / Code already used");
        require(MerkleProof.verifyProof(_proof, root, keccak256(abi.encodePacked(_code))), "Invalid code");

        sentToAddress[_dest] = true;
        codeUsed[_code] = true;
        
        require(SNT.transfer(_dest, sntAmount), "Transfer did not work");
        _dest.transfer(ethAmount);
        
        emit AddressFunded(_dest, _code, ethAmount, sntAmount);
    }
    
     
     
     
     
    function updateSettings(uint _ethAmount, uint _sntAmount, bytes32 _root) public onlyController {
        ethAmount = _ethAmount;
        sntAmount = _sntAmount;
        root = _root;
        
    }

    function manualSend(address _dest, bytes5 _code) public onlyController {
        require(!sentToAddress[_dest] && !codeUsed[_code], "Funds already sent / Code already used");

        sentToAddress[_dest] = true;
        codeUsed[_code] = true;

        require(SNT.transfer(_dest, sntAmount), "Transfer did not work");
        _dest.transfer(ethAmount);
        
        emit AddressFunded(_dest, _code, ethAmount, sntAmount);
    }
    
     
    function boom() public onlyController {
        uint sntBalance = SNT.balanceOf(address(this));
        require(SNT.transfer(msg.sender, sntBalance), "Transfer did not work");
        selfdestruct(msg.sender);
    }
    
     
    function retrieveFunds() public onlyController {
        uint sntBalance = SNT.balanceOf(address(this));
        require(SNT.transfer(msg.sender, sntBalance), "Transfer did not work");
    }


    function() public payable {
          
    }

    
}