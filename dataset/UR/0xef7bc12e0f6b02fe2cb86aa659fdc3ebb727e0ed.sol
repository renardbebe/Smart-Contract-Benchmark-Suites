 

 

 
 
 


pragma solidity 0.5.13;

contract OrchidLocation {
    struct Location {
        uint256 set_;
        bytes url_;
        bytes tls_;
        bytes gpg_;
    }

    mapping (address => Location) private locations_;

    event Update(address indexed provider);

    function poke() external {
        Location storage location = locations_[msg.sender];
        location.set_ = block.timestamp;
        emit Update(msg.sender);
    }

    function move(bytes calldata url, bytes calldata tls, bytes calldata gpg) external {
        Location storage location = locations_[msg.sender];
        location.set_ = block.timestamp;
        location.url_ = url;
        location.tls_ = tls;
        location.gpg_ = gpg;
        emit Update(msg.sender);
    }

    function look(address target) external view returns (uint256, bytes memory, bytes memory, bytes memory) {
        Location storage location = locations_[target];
        return (location.set_, location.url_, location.tls_, location.gpg_);
    }
}