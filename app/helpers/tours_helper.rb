# -*- coding: undecided -*-
module ToursHelper
  def status_filter_present?
    %w(draft building published failed edited).any?{|k| params[k]}
  end

  def all_statuses_class
    {:class => status_filter_present? ? '' : 'selected'}
  end

  def status_filter(filter_type)
    additional_class = params[filter_type] ? ' selected' : ''
    {:class => filter_type.to_s + additional_class}
  end

  def formatted_build_message(tour)
    escape_javascript(tour.build_message)
  end

  def distance_in_kilometers(km)
    km == 1 ? "#{km} kilometer" : "#{km} kilometers"
  end

  def distance_in_time(minutes)
    parts = []

    if minutes/60 != 0
      hours = minutes / 60
      parts << hours << (hours == 1 ? "hour" : "hours")
    end

    if minutes%60 != 0
      mins = minutes % 60
      parts << mins << (mins == 1 ? "minute" : "minutes")
    end

    parts.join(" ")
  end

  def options_for_country
    [
["Choose country", ""],
["United Kingdom", "GB"],
["United States", "US"],
["Canada", "CA"],
["Afghanistan", "AF"],
["Albania", "AL"],
["Algeria", "DZ"],
["American Samoa", "AS"],
["Andorra", "AD"],
["Angola", "AO"],
["Anguilla", "AI"],
["Antarctica", "AQ"],
["Antigua And Barbuda", "AG"],
["Argentina", "AR"],
["Armenia", "AM"],
["Aruba", "AW"],
["Australia", "AU"],
["Austria", "AT"],
["Azerbaijan", "AZ"],
["Bahamas", "BS"],
["Bahrain", "BH"],
["Bangladesh", "BD"],
["Barbados", "BB"],
["Belarus", "BY"],
["Belgium", "BE"],
["Belize", "BZ"],
["Benin", "BJ"],
["Bermuda", "BM"],
["Bhutan", "BT"],
["Bolivia", "BO"],
["Bosnia And Herzegovina", "BA"],
["Botswana", "BW"],
["Bouvet Island", "BV"],
["Brazil", "BR"],
["British Indian Ocean Territory", "IO"],
["Brunei Darussalam", "BN"],
["Bulgaria", "BG"],
["Burkina Faso", "BF"],
["Burundi", "BI"],
["Cambodia", "KH"],
["Cameroon", "CM"],
["Canada", "CA"],
["Cape Verde", "CV"],
["Cayman Islands", "KY"],
["Central African Republic", "CF"],
["Chad", "TD"],
["Chile", "CL"],
["China", "CN"],
["Christmas Island", "CX"],
["Cocos (keeling) Islands", "CC"],
["Colombia", "CO"],
["Comoros", "KM"],
["Congo", "CG"],
["Congo, The Democratic Republic Of The", "CD"],
["Cook Islands", "CK"],
["Costa Rica", "CR"],
["Cote D'ivoire", "CI"],
["Croatia", "HR"],
["Cuba", "CU"],
["Cyprus", "CY"],
["Czech Republic", "CZ"],
["Denmark", "DK"],
["Djibouti", "DJ"],
["Dominica", "DM"],
["Dominican Republic", "DO"],
["East Timor", "TP"],
["Ecuador", "EC"],
["Egypt", "EG"],
["El Salvador", "SV"],
["Equatorial Guinea", "GQ"],
["Eritrea", "ER"],
["Estonia", "EE"],
["Ethiopia", "ET"],
["Falkland Islands (malvinas)", "FK"],
["Faroe Islands", "FO"],
["Fiji", "FJ"],
["Finland", "FI"],
["France", "FR"],
["French Guiana", "GF"],
["French Polynesia", "PF"],
["French Southern Territories", "TF"],
["Gabon", "GA"],
["Gambia", "GM"],
["Georgia", "GE"],
["Germany", "DE"],
["Ghana", "GH"],
["Gibraltar", "GI"],
["Greece", "GR"],
["Greenland", "GL"],
["Grenada", "GD"],
["Guadeloupe", "GP"],
["Guam", "GU"],
["Guatemala", "GT"],
["Guinea", "GN"],
["Guinea-bissau", "GW"],
["Guyana", "GY"],
["Haiti", "HT"],
["Heard Island And Mcdonald Islands", "HM"],
["Holy See (vatican City State)", "VA"],
["Honduras", "HN"],
["Hong Kong", "HK"],
["Hungary", "HU"],
["Iceland", "IS"],
["India", "IN"],
["Indonesia", "ID"],
["Iran, Islamic Republic Of", "IR"],
["Iraq", "IQ"],
["Ireland", "IE"],
["Israel", "IL"],
["Italy", "IT"],
["Jamaica", "JM"],
["Japan", "JP"],
["Jordan", "JO"],
["Kazakstan", "KZ"],
["Kenya", "KE"],
["Kiribati", "KI"],
["Korea, Democratic People's Republic Of", "KP"],
["Korea, Republic Of", "KR"],
["Kosovo", "KV"],
["Kuwait", "KW"],
["Kyrgyzstan", "KG"],
["Lao People's Democratic Republic", "LA"],
["Latvia", "LV"],
["Lebanon", "LB"],
["Lesotho", "LS"],
["Liberia", "LR"],
["Libyan Arab Jamahiriya", "LY"],
["Liechtenstein", "LI"],
["Lithuania", "LT"],
["Luxembourg", "LU"],
["Macau", "MO"],
["Macedonia, The Former Yugoslav Republic Of", "MK"],
["Madagascar", "MG"],
["Malawi", "MW"],
["Malaysia", "MY"],
["Maldives", "MV"],
["Mali", "ML"],
["Malta", "MT"],
["Marshall Islands", "MH"],
["Martinique", "MQ"],
["Mauritania", "MR"],
["Mauritius", "MU"],
["Mayotte", "YT"],
["Mexico", "MX"],
["Micronesia, Federated States Of", "FM"],
["Moldova, Republic Of", "MD"],
["Monaco", "MC"],
["Mongolia", "MN"],
["Montserrat", "MS"],
["Montenegro", "ME"],
["Morocco", "MA"],
["Mozambique", "MZ"],
["Myanmar", "MM"],
["Namibia", "NA"],
["Nauru", "NR"],
["Nepal", "NP"],
["Netherlands", "NL"],
["Netherlands Antilles", "AN"],
["New Caledonia", "NC"],
["New Zealand", "NZ"],
["Nicaragua", "NI"],
["Niger", "NE"],
["Nigeria", "NG"],
["Niue", "NU"],
["Norfolk Island", "NF"],
["Northern Mariana Islands", "MP"],
["Norway", "NO"],
["Oman", "OM"],
["Pakistan", "PK"],
["Palau", "PW"],
["Palestinian Territory, Occupied", "PS"],
["Panama", "PA"],
["Papua New Guinea", "PG"],
["Paraguay", "PY"],
["Peru", "PE"],
["Philippines", "PH"],
["Pitcairn", "PN"],
["Poland", "PL"],
["Portugal", "PT"],
["Puerto Rico", "PR"],
["Qatar", "QA"],
["Reunion", "RE"],
["Romania", "RO"],
["Russian Federation", "RU"],
["Rwanda", "RW"],
["Saint Helena", "SH"],
["Saint Kitts And Nevis", "KN"],
["Saint Lucia", "LC"],
["Saint Pierre And Miquelon", "PM"],
["Saint Vincent And The Grenadines", "VC"],
["Samoa", "WS"],
["San Marino", "SM"],
["Sao Tome And Principe", "ST"],
["Saudi Arabia", "SA"],
["Senegal", "SN"],
["Serbia", "RS"],
["Seychelles", "SC"],
["Sierra Leone", "SL"],
["Singapore", "SG"],
["Slovakia", "SK"],
["Slovenia", "SI"],
["Solomon Islands", "SB"],
["Somalia", "SO"],
["South Africa", "ZA"],
["South Georgia And The South Sandwich Islands", "GS"],
["Spain", "ES"],
["Sri Lanka", "LK"],
["Sudan", "SD"],
["Suriname", "SR"],
["Svalbard And Jan Mayen", "SJ"],
["Swaziland", "SZ"],
["Sweden", "SE"],
["Switzerland", "CH"],
["Syrian Arab Republic", "SY"],
["Taiwan", "TW"],
["Tajikistan", "TJ"],
["Tanzania, United Republic Of", "TZ"],
["Thailand", "TH"],
["Togo", "TG"],
["Tokelau", "TK"],
["Tonga", "TO"],
["Trinidad And Tobago", "TT"],
["Tunisia", "TN"],
["Turkey", "TR"],
["Turkmenistan", "TM"],
["Turks And Caicos Islands", "TC"],
["Tuvalu", "TV"],
["Uganda", "UG"],
["Ukraine", "UA"],
["United Arab Emirates", "AE"],
["United Kingdom", "GB"],
["United States", "US"],
["United States Minor Outlying Islands", "UM"],
["Uruguay", "UY"],
["Uzbekistan", "UZ"],
["Vanuatu", "VU"],
["Venezuela", "VE"],
["Viet Nam", "VN"],
["Virgin Islands, British", "VG"],
["Virgin Islands, U.s.", "VI"],
["Wallis And Futuna", "WF"],
["Western Sahara", "EH"],
["Yemen", "YE"],
["Zambia", "ZM"],
["Zimbabwe", "ZW"]
   ]

  end

  # used in locations/_form.html.haml 
  def country_to_code_hash
    options_for_country.collect{|country, code| "\"#{country}\": \"#{code}\""}.join(', ')
  end

  def reverse_options_for_country
    options_for_country.inject({}) do |sum, country|
      sum.merge!({country[1] => country[0]})
    end.collect{|code, country| "\"#{code}\": \"#{country}\""}.join(', ')
  end

  def country_from_iso_code(code)
    @countries ||= options_for_country.inject({}){|sum, o| sum.merge!({o[1] => o[0]}) }
    @countries[code]
  end
end
