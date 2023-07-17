## Stable-Coin-Protocol
This project builds out a stable coin protocol where you can deposit collateral in ERC20 token (weth or wbtc) to mint the protocol stable coin. This project is inspired by the famous web3 project MakerDAO.

## In this project we are making a stable coin and the details about what type of stable coin we are making are as below;

# Relative Stability

Our stable coin would be pegged to a dollar (meaning we are making a pegged/anchored stable coin). Note that to always make sure that our stable coin is always equal to $1 we would implement the below mechanism;

1. Implement a chainlink priceFeed to always get the current BTC/USD or ETH/USD price before calling the mint or burn function.
2. call the function that would exchange the ETH/BTC for our stable coin.

# Stability Mechanism

We would be making a stable coin that uses an algorithmic stability mechanism (meaning that the minting and burning of our stable coin is done purely by a smart contract without any intefrence whatsoever of human). Not to make sure our stability mechanism is truly algorithm we would have some implementation in our contract that enforce the fact that people can only mint our stable coin quantity that is below their provided collateral

# Collateral Type

We would be using an exogenous collateral type for our stable coin (meaning that our collateral isn't controlled or issued by us). one more thing to notr is we are using a crypto asset as collateral.

We are using two crypto assets as our collateral which are ;

1.  ETH
2.  BTC

it isn't logical to accept BTC on an ethereum based smart contract so we would be implementing the ERC20 version of ETH AND BTC as the collateral that is acceptable (i.e WETH, WBTC);

# Important Security Considerations

1. what are our invariant/properties? 
