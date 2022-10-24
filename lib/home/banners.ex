defmodule Home.Banners.Banner do
  @moduledoc """
  A banner object, including the image and its display properties.
  """
  defstruct path: nil,
            tags: [],
            caption: nil,
            album: nil,
            freq: 1,
            pos: {"center", "center"}

  @doc """
  Gets the CSS position string for the banner.
  """
  def position(%__MODULE__{pos: {x, y}}) do
    "#{x} #{y}"
  end
end

defmodule Home.Banners do
  @moduledoc """
  Source material for banner images.
  """

  # The collection of everything in `banners/`.
  @banners [
    %__MODULE__.Banner{
      path: "2013-07-12_002.jpg",
      tags: [
        :sunset,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation waterfront at dusk",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2013-08-04_002.jpg",
      tags: [
        :sky,
        :rksr
      ],
      caption: "Circumscribed rainbow over Rota-Kiwan Scout Reservation",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2014-06-18T21-50-56.jpg",
      tags: [
        :panorama,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation waterfront",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2014-06-18T21-52-19.jpg",
      tags: [
        :sunset,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation waterfront at twilight"
    },
    %__MODULE__.Banner{
      path: "2014-06-18T21-52-46.jpg",
      tags: [
        :sunset,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation waterfront at twilight",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2014-06-19T20-19-50.jpg",
      tags: [
        :sunset,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation waterfront at twilight",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2014-06-19T20-21-09.jpg",
      tags: [
        :panorama,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation waterfront",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2014-07-05_004.jpg",
      tags: [
        :dune
      ],
      caption: "Sand dunes overlooking Lake Michigan, near Great Bear Dunes",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-05_011.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Approaching Mackinac Island",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-05_044.jpg",
      tags: [
        :sea,
        :sky,
        :sunset
      ],
      caption: "Snail Shell Harbor, Fayette Historic State Park, Michigan (Upper Peninsula)",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-05T12-54-24.jpg",
      freq: 10,
      tags: [
        :dune,
        :sky
      ],
      caption: "Sand dunes overlooking Lake Michigan, near Great Bear Dunes",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-05T21-37-04.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Snail Shell Harbor, Fayette Historic State Park, Michigan (Upper Peninsula)",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-05T21-37-45.jpg",
      tags: [
        :panorama,
        :sea,
        :sky
      ],
      caption: "Snail Shell Harbor, Fayette Historic State Park, Michigan (Upper Peninsula)",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-05T21-45-22.jpg",
      tags: [
        :sea
      ],
      caption: "Snail Shell Harbor, Fayette Historic State Park, Michigan (Upper Peninsula)"
    },
    %__MODULE__.Banner{
      path: "2014-07-06_024.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "An island in Lake Michigan, from a road trip circle tour I took once",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-07-07T21-27-33.jpg",
      tags: [
        :sea,
        :sky,
        :sunset
      ],
      caption: "A tall ship on Lake Michigan, probably near St. Joseph, MI",
      album: :lmct
    },
    %__MODULE__.Banner{
      path: "2014-08-04_002.jpg",
      tags: [
        :sky,
        :sunset,
        :waterfront
      ],
      caption: "Rota-Kiwan Scout Reservation, waterfront, dusk",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2015-05-27T16-22-02.jpg",
      tags: [
        :clouds,
        :sky,
        :waterfront
      ],
      caption: "Lake at Gerber Scout Ranch, taken during National Camp School"
    },
    %__MODULE__.Banner{
      path: "2015-05-27T17-03-48.jpg",
      tags: [
        :clouds,
        :sky,
        :waterfront
      ],
      caption: "Lake at Gerber Scout Ranch, taken during National Camp School"
    },
    %__MODULE__.Banner{
      path: "2015-07-09T19-56-50.jpg",
      tags: [
        :panorama,
        :waterfront,
        :rksr
      ],
      caption: "Rota-Kiwan Scout Reservation, waterfront",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2015-08-14T20-03-48.jpg",
      tags: [
        :clouds,
        :sea,
        :sky,
        :storm
      ],
      caption: "Storm clouds at sunset over Islamorada, FL"
    },
    %__MODULE__.Banner{
      path: "2015-08-14T20-04-01.jpg",
      tags: [
        :clouds,
        :sea,
        :sky,
        :storm
      ],
      caption: "Storm clouds at sunset over Islamorada, FL"
    },
    %__MODULE__.Banner{
      path: "2015-08-16T20-10-17.jpg",
      tags: [
        :clouds,
        :sea,
        :sky,
        :sunset
      ],
      caption: "Clouds at sunset over Islamorada, FL"
    },
    %__MODULE__.Banner{
      path: "2015-08-16T20-10-33.jpg",
      tags: [
        :clouds,
        :sea,
        :sky,
        :sunset
      ],
      caption: "Clouds at sunset over Islamorada, FL"
    },
    %__MODULE__.Banner{
      path: "2015-08-16T20-10-45.jpg",
      tags: [
        :clouds,
        :sea,
        :sky,
        :sunset
      ],
      caption: "Clouds at sunset over Islamorada, FL"
    },
    %__MODULE__.Banner{
      path: "2015-08-17T08-54-17.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Departing Islamorada for a dive day"
    },
    %__MODULE__.Banner{
      path: "2015-08-17T08-54-42.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Departing Islamorada for a dive day"
    },
    %__MODULE__.Banner{
      path: "2015-08-17T08-55-00.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Departing Islamorada for a dive day"
    },
    %__MODULE__.Banner{
      path: "2015-08-17T08-55-07.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Departing Islamorada for a dive day"
    },
    %__MODULE__.Banner{
      path: "2015-08-18T17-42-54.jpg",
      tags: [
        :sky,
        :skyline
      ],
      caption: "Driving past Miami"
    },
    %__MODULE__.Banner{
      path: "2015-08-21T15-13-48.jpg",
      tags: [
        :clouds,
        :sky
      ],
      caption: "Clouds over my home in Jonesville, MI"
    },
    %__MODULE__.Banner{
      path: "2015-08-21T15-14-30.jpg",
      tags: [
        :sky
      ],
      caption: "Backyard in Jonesville, MI",
      pos: {"bottom", "right"}
    },
    %__MODULE__.Banner{
      path: "2015-08-21T15-14-59.jpg",
      tags: [
        :clouds,
        :sky
      ],
      caption: "Clouds over my home in Jonesville, MI"
    },
    %__MODULE__.Banner{
      path: "2016-07-31T11-56-43.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T11-59-09.jpg",
      tags: [
        :sea,
        :sky
      ],
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T12-16-22.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T12-39-16.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T13-37-11.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T14-46-52.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T15-16-48.jpg",
      tags: [
        :sea,
        :sky
      ],
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-07-31T15-29-58.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-18-00.jpg",
      tags: [
        :lighthouse,
        :sea
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-18-04.jpg",
      tags: [
        :lighthouse,
        :sea
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-18-25.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-19-30.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-21-06.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-23-01.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-23-37.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-26-08.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-26-16.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-26-26.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-27-11.jpg",
      tags: [
        :sea,
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-28-04.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-28-20.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-29-12.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-29-57.jpg",
      tags: [
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-30-57.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-33-41.jpg",
      tags: [
        :sea
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-35-06.jpg",
      tags: [
        :sea
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-37-57.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-38-10.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-02T19-38-13.jpg",
      tags: [
        :lighthouse
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-04T21-02-16.jpg",
      tags: [
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-08-04T21-03-40.jpg",
      tags: [
        :sky
      ],
      caption: "Taken on Lake Huron, near St. Joseph Island, Ontario",
      album: :lindsee
    },
    %__MODULE__.Banner{
      path: "2016-09-04T09-16-38.jpg",
      tags: [
        :sea
      ],
      caption: "Atlantic Ocean from Ogunquit, ME",
      album: :maine
    },
    %__MODULE__.Banner{
      path: "2016-09-05T12-40-00.jpg",
      tags: [
        :sea,
        :waves
      ],
      caption: "Atlantic Ocean from Ogunquit, ME",
      album: :maine
    },
    %__MODULE__.Banner{
      path: "2016-09-05T12-41-06.jpg",
      tags: [
        :sea,
        :waves
      ],
      caption: "Atlantic Ocean from Ogunquit, ME",
      album: :maine
    },
    %__MODULE__.Banner{
      path: "2016-09-05T12-41-10.jpg",
      tags: [
        :sea,
        :waves
      ],
      caption: "Atlantic Ocean from Ogunquit, ME",
      album: :maine
    },
    %__MODULE__.Banner{
      path: "2016-09-05T12-41-16.jpg",
      tags: [
        :sea,
        :waves
      ],
      caption: "Atlantic Ocean from Ogunquit, ME",
      album: :maine
    },
    %__MODULE__.Banner{
      path: "2016-09-16T20-16-05.jpg",
      tags: [
        :night,
        :waterfront
      ],
      caption: "Looking north over Bass Lake, Rota-Kiwan Scout Reservation",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2016-09-16T20-20-39.jpg",
      tags: [
        :night,
        :waterfront
      ],
      caption: "Looking north over Bass Lake, Rota-Kiwan Scout Reservation",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2016-09-17T17-03-35.jpg",
      tags: [
        :waterfront
      ],
      caption: "Looking north over Bass Lake, Rota-Kiwan Scout Reservation",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2016-09-17T17-04-58.jpg",
      tags: [
        :waterfront
      ],
      caption: "Looking north over Bass Lake, Rota-Kiwan Scout Reservation",
      album: :rksr
    },
    %__MODULE__.Banner{
      path: "2017-01-21T13-26-41.jpg",
      tags: [
        :mountains,
        :snow
      ],
      caption: "Bear River Mountains, between Logan and Garden City (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-21T13-27-19.jpg",
      tags: [
        :mountains,
        :snow
      ],
      caption: "Bear River Mountains, between Logan and Garden City (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T16-27-41-942.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T16-30-49-237.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T16-33-00-014.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T16-34-51-876.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T16-37-06-465.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T16-37-29-086.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T17-16-06-375.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T17-16-37-647.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T17-16-45-530.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T17-19-33-873.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-27T17-21-14-438.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Sardine Canyon, between Brigham City and Wellsville (UT)",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-21-36-064.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Approaching Beaver Mountain, in the Bear River Mountains",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-21-48-063.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Approaching Beaver Mountain, in the Bear River Mountains",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-21-53-827.jpg",
      tags: [
        :mountains,
        :sky,
        :snow
      ],
      caption: "Approaching Beaver Mountain, in the Bear River Mountains",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-35-12-795.jpg",
      tags: [
        :lake,
        :sky,
        :snow
      ],
      caption: "Overlooking Bear Lake, at the east end of Logan Canyon",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-35-25-828.jpg",
      tags: [
        :lake,
        :sky,
        :snow
      ],
      caption: "Overlooking Bear Lake, at the east end of Logan Canyon",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-37-41-650.jpg",
      tags: [
        :lake,
        :sky,
        :snow
      ],
      caption: "Overlooking Bear Lake, at the east end of Logan Canyon",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T08-50-37.jpg",
      tags: [
        :lake,
        :panorama,
        :sky,
        :snow
      ],
      freq: 10,
      caption: "Full circle panorama on Bear Lake",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2017-01-28T12-02-41.jpg",
      tags: [
        :mountains,
        :panorama,
        :sky,
        :snow
      ],
      caption: "View from Beaver Mountain summit",
      album: :utah
    },
    %__MODULE__.Banner{
      path: "2018-08-12T11-29-10.jpg",
      tags: [
        :hot_spring,
        :yellowstone
      ],
      caption: "A hot spring at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T11-31-30.jpg",
      tags: [
        :hot_spring,
        :yellowstone
      ],
      caption: "A hot spring at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T11-31-50.jpg",
      tags: [
        :river,
        :geyser,
        :yellowstone
      ],
      caption: "A river at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T11-35-22.jpg",
      tags: [
        :geyser,
        :yellowstone
      ],
      caption: "Lion geyser at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T11-37-48.jpg",
      tags: [
        :river,
        :yellowstone
      ],
      caption: "A river at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T11-51-33.jpg",
      tags: [
        :hot_spring,
        :yellowstone
      ],
      caption: "A hot spring at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-00-33.jpg",
      tags: [
        :geyser,
        :yellowstone
      ],
      caption: "Giant Geyser at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-05-09.jpg",
      tags: [
        :geyser,
        :yellowstone
      ],
      caption: "Grotto Geyser at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-07-25.jpg",
      tags: [
        :geyser,
        :yellowstone
      ],
      caption: "Grotto Geyser at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-15-21.jpg",
      tags: [
        :hot_spring,
        :yellowstone
      ],
      caption: "Morning Glory Pool at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-26-33.jpg",
      tags: [
        :mountains,
        :yellowstone
      ],
      caption: "Mountains at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-26-37.jpg",
      tags: [
        :mountains,
        :yellowstone
      ],
      caption: "Mountains at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-27-44.jpg",
      tags: [
        :hot_spring,
        :yellowstone
      ],
      caption: "A hot spring at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-29-10.jpg",
      tags: [
        :river,
        :yellowstone
      ],
      caption: "A river at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-35-28.jpg",
      tags: [
        :mountains,
        :yellowstone
      ],
      caption: "Mountains at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-38-29.jpg",
      tags: [
        :geyser,
        :yellowstone
      ],
      caption: "Castle Geyser at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T12-38-45.jpg",
      tags: [
        :geyser,
        :yellowstone
      ],
      caption: "Castle Geyser at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T15-40-10.jpg",
      tags: [
        :buffalo,
        :yellowstone
      ],
      caption: "Buffalo at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T15-40-17.jpg",
      tags: [
        :buffalo,
        :yellowstone
      ],
      caption: "Buffalo at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T15-40-23.jpg",
      tags: [
        :buffalo,
        :yellowstone
      ],
      caption: "Buffalo at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T15-41-57.jpg",
      tags: [
        :buffalo,
        :yellowstone
      ],
      caption: "Buffalo at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T15-49-13.jpg",
      tags: [
        :buffalo,
        :yellowstone
      ],
      caption: "Buffalo at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T16-33-55.jpg",
      tags: [
        :canyon,
        :waterfall,
        :yellowstone
      ],
      caption: "Yellowstone Falls at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T17-04-08.jpg",
      tags: [
        :canyon,
        :yellowstone
      ],
      caption: "Grand Canyon of the Yellowstone at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T17-25-03.jpg",
      tags: [
        :canyon,
        :yellowstone
      ],
      caption: "Grand Canyon of the Yellowstone at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T18-55-23.jpg",
      tags: [
        :river,
        :yellowstone
      ],
      caption: "Madison River at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-12T18-55-29.jpg",
      tags: [
        :river,
        :yellowstone
      ],
      caption: "Madison River at Yellowstone National Park",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-13T08-38-52.jpg",
      tags: [
        :river
      ],
      caption: "A river next to my campsite, Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-13T11-12-19.jpg",
      tags: [
        :waterfall
      ],
      caption: "A waterfall in Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-13T21-22-29.jpg",
      tags: [
        :sunset
      ],
      caption: "Sunset over my campsite, Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-14T07-49-41.jpg",
      tags: [
        :sunrise
      ],
      caption: "Sunrise at my campsite, Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-14T07-49-51.jpg",
      tags: [
        :sunrise
      ],
      caption: "Sunrise at my campsite, Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-14T07-49-56.jpg",
      tags: [
        :sunrise
      ],
      caption: "Sunrise at my campsite, Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-14T07-50-13.jpg",
      tags: [
        :sunrise
      ],
      caption: "Sunrise at my campsite, Island Park, ID",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-14T12-01-16.jpg",
      tags: [
        :mountain,
        :grand_teton
      ],
      caption: "Grand Teton",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-14T13-09-55.jpg",
      tags: [
        :grand_teton,
        :lake
      ],
      caption: "Grand Teton, as seen from a lake partway up it",
      album: :yellowstone
    },
    %__MODULE__.Banner{
      path: "2018-08-15T13-18-22.jpg",
      tags: [
        :waterfall
      ],
      caption: "Mesa Falls, near Island Park, ID",
      album: :yellowstone
    }
  ]

  @album_names %{
    rksr: "RKSR",
    lindsee: "Lake Ontario Trip (2016)",
    maine: "Family Reünion (2016)",
    utah: "Utah",
    yellowstone: "Yellowstone Trip (2018)"
  }

  # The collection of everything in `oeuvre/`.
  @teslore [
    map_cyrod: %__MODULE__.Banner{
      path: "map-cyrod.jpg",
      tags: ["map"],
      caption: "A section of the map of Tamriel, centered on Imperial City"
    },
    map_skyrim: %__MODULE__.Banner{
      path: "map-skyrim.jpg",
      tags: ["map"],
      caption: "A section of the map of Tamriel, showing northern Skyrim"
    },
    map_stylized: %__MODULE__.Banner{
      path: "map-stylized.jpg",
      tags: ["map"],
      caption: "A section of the map of Tamriel, showing Morrowind"
    },
    map_wilderness: %__MODULE__.Banner{
      path: "map-wilderness.jpg",
      tags: ["map"],
      caption: "A section of the map of Tamriel, showing wilderness"
    },
    text_daedric: %__MODULE__.Banner{
      path: "text-daedric.jpg",
      tags: ["text"],
      caption: "Some Daedric text"
    },
    text_oghma: %__MODULE__.Banner{
      path: "text-oghma.jpg",
      tags: ["text"],
      caption: "A section of the Oghma Infinium"
    }
  ]

  def get_tags() do
    @banners
    |> Stream.map(fn %__MODULE__.Banner{tags: tags} -> tags end)
    |> Stream.flat_map(fn x -> x end)
    |> Enum.into(MapSet.new())
    |> Enum.to_list()
  end

  def by_albums() do
    @banners
    |> Stream.map(fn %__MODULE__.Banner{album: album} = banner -> {album, banner} end)
    |> Enum.reduce(%{}, fn {album, banner}, map ->
      Map.update(map, album, [], fn list -> [banner | list] end)
    end)
    |> Stream.map(fn {k, v} -> {Map.get(@album_names, k, "Miscellaneous"), v} end)
    |> Enum.into(Map.new())
  end

  @doc """
  Filters banner objects that match a given tag.
  """
  def filter_tag(banners, tag \\ nil) do
    banners
    |> Stream.filter(fn banner ->
      if tag do
        Enum.member?(banner.tags, tag)
      else
        true
      end
    end)
  end

  @doc """
  Selects one banner at random from the main collection.
  """
  def true_random(), do: true_random(nil)

  def true_random(tag) do
    banners = @banners |> filter_tag(tag)
    idx = banners |> length |> :rand.uniform()
    out = banners |> Enum.at(idx)
    name = out.name
    %{out | path: ["banners", name] |> Path.join()}
  end

  @doc """
  Selects one banner at random from the main collection with respect to their
  specified frequency weights.
  """
  def weighted_random(), do: weighted_random(nil)

  def weighted_random(tag) do
    banners = @banners |> filter_tag(tag)

    idx =
      banners
      |> Stream.map(& &1.freq)
      |> Enum.reduce(&(&1 + &2))
      |> :rand.uniform()
      |> (fn num -> num - 1 end).()

    out =
      banners
      |> Stream.map(&{&1, &1.freq})
      |> Enum.reduce(fn {next, weight}, {prev, sum} ->
        step = sum + weight
        # Advance the image until the index is less than the cursor, then freeze.
        if idx > step do
          {next, step}
        else
          {prev, step}
        end
      end)
      |> elem(0)

    path = out.path
    %{out | path: ["banners", path] |> Path.join()}
  end

  @doc """
  Selects a named banner from the oeuvre collection.

  If `name` is `nil`, then the banner is random. If `name` is not known, then
  a default banner is used.

  `name` is cast to an atom, so this might leak memory on unknown input?
  """
  def teslore(nil) do
    idx = @teslore |> length |> :rand.uniform()
    {_, out} = @teslore |> Enum.at(idx - 1)
    path = out.path
    %{out | path: ["oeuvre", path] |> Path.join()}
  end

  def teslore(name) do
    out =
      Keyword.get(
        @teslore,
        name |> String.replace("-", "_") |> String.to_atom(),
        @teslore[:text_oghma]
      )

    path = out.path
    %{out | path: ["oeuvre", path] |> Path.join()}
  end
end
