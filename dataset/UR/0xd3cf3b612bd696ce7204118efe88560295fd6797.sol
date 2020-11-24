 

 
pragma solidity 0.4.18;

contract Owned {
     
    address public owner = msg.sender;
     
    function replaceOwner(address newOwner) external returns(bool success) {
        require( isOwner() );
        owner = newOwner;
        return true;
    }
     
    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }
     
    modifier onlyForOwner {
        require( isOwner() );
        _;
    }
}

contract Token {
     
    function mint(address owner, uint256 value) external returns (bool success) {}
}

contract Fork is Owned {
     
    address public uploader;
    address public tokenAddress;
     
    function Fork(address _uploader) public {
        uploader = _uploader;
    }
     
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        tokenAddress = newTokenAddress;
    }
    function upload(address[] addr, uint256[] amount) external onlyForUploader {
        require( addr.length == amount.length );
        for ( uint256 a=0 ; a<addr.length ; a++ ) {
            require( Token(tokenAddress).mint(addr[a], amount[a]) );
        }
    }
     
    modifier onlyForUploader {
        require( msg.sender == uploader );
        _;
    }
}