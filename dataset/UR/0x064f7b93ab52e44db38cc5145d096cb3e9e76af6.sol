 

pragma solidity ^0.4.11;
contract Reviews{
    struct Review{
        string reviewContent;
        string place;
        string siteName;
        uint rate;
        string UserName;
    }
	struct jsonReview{
        string hotel_name;
        uint id;
        string review_content;
        string time;
    }
	event LogReviewAdded(string content , string place, string site);
    event LogNewOraclizeQuery(string description);
    mapping(bytes32 => bytes32 ) validIdstoSite;
    mapping (address => Review[]) siteToReviews;
    mapping (string => Review[]) placeToReviews;
    
    constructor()public
	{
        userAddReviews("Best Company for ETH Based DAPP Development","Gaffer IT Solutions Pvt Ltd","Tasleem Ali",5);
    }
    
	function userAddReviews(string memory _reviewContent, string memory _place, string memory _userName, uint _rate) public{
        Review memory _review = Review({
            reviewContent: _reviewContent,
            place: _place,
            siteName: "OwnSite",
            rate: _rate,
            UserName: _userName
            });
        siteToReviews[msg.sender].push(_review);
        placeToReviews[_place].push(_review);
    }
    
	function searchReview(string memory placeName,uint id) public view returns(string memory , string memory , string memory, uint ) {
        return (
                placeToReviews[placeName][id].reviewContent,
                placeToReviews[placeName][id].place,
                placeToReviews[placeName][id].siteName,
                placeToReviews[placeName][id].rate
        );
    }
}